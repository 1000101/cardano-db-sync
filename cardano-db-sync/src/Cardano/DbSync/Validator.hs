module Cardano.DbSync.Validator where

import           Control.Monad.Trans.Except.Exit (orDie)

import           Control.Tracer (Tracer)

import           Cardano.BM.Data.Tracer (ToLogObject (..))
import qualified Cardano.BM.Setup as Logging
import           Cardano.BM.Trace (Trace, appendName, logInfo, logWarning)
import qualified Cardano.BM.Trace as Logging

import qualified Cardano.Chain.Genesis as Byron
import           Cardano.Client.Subscription (subscribe)
import qualified Cardano.Crypto as Crypto

import           Cardano.Db (LogFileDir (..))
import qualified Cardano.Db as DB
import qualified Cardano.Db.Delete as DB
import           Cardano.DbSync.Config
import           Cardano.DbSync.Database
import           Cardano.DbSync.DbAction
import           Cardano.DbSync.Era
import           Cardano.DbSync.Error
import           Cardano.DbSync.LedgerState
import           Cardano.DbSync.Metrics
import           Cardano.DbSync.Plugin (DbSyncNodePlugin (..))
import           Cardano.DbSync.Plugin.Default (defDbSyncNodePlugin)
import           Cardano.DbSync.Rollback (unsafeRollback)
import           Cardano.DbSync.StateQuery (StateQueryTMVar, getSlotDetails, localStateQueryHandler,
                   newStateQueryTMVar)
import           Cardano.DbSync.Tracing.ToObjectOrphans ()
import           Cardano.DbSync.Types
import           Cardano.DbSync.Util

import           Cardano.Prelude hiding (Nat, option, (%))

import           Cardano.Slotting.Slot (SlotNo (..), WithOrigin (..), at)

import qualified Codec.CBOR.Term as CBOR

import           Control.Monad.Trans.Except.Exit (orDie)
import           Control.Monad.Trans.Except.Extra (hoistEither)

import qualified Data.ByteString.Lazy as BSL
import           Data.Functor.Contravariant (contramap)
import           Data.Ord
import qualified Data.Text as Text

import           Network.Mux (MuxTrace, WithMuxBearer)
import           Network.Mux.Types (MuxMode (..))

import           Network.TypedProtocol.Pipelined (Nat (Succ, Zero))
import           Ouroboros.Network.Driver.Simple (runPipelinedPeer)

import           Ouroboros.Consensus.Block.Abstract (CodecConfig, ConvertRawHash (..))
import           Ouroboros.Consensus.Byron.Ledger.Config (mkByronCodecConfig)
import           Ouroboros.Consensus.Byron.Node ()
import           Ouroboros.Consensus.Cardano.Block (CardanoEras, CodecConfig (..))
import           Ouroboros.Consensus.Cardano.Node ()
import           Ouroboros.Consensus.HardFork.History.Qry (Interpreter)
import           Ouroboros.Consensus.Network.NodeToClient (ClientCodecs, cChainSyncCodec,
                   cStateQueryCodec, cTxSubmissionCodec)
import           Ouroboros.Consensus.Node.ErrorPolicy (consensusErrorPolicy)
import           Ouroboros.Consensus.Shelley.Ledger.Config (CodecConfig (ShelleyCodecConfig))
import           Ouroboros.Consensus.Shelley.Protocol (StandardCrypto)

import           Ouroboros.Network.Block (BlockNo (..), HeaderHash, Point (..), Tip (..), blockNo,
                   genesisPoint, getTipBlockNo, getTipPoint)
import           Ouroboros.Network.Mux (MuxPeer (..), RunMiniProtocol (..))
import           Ouroboros.Network.NodeToClient (ClientSubscriptionParams (..), ConnectionId,
                   ErrorPolicyTrace (..), Handshake, IOManager, LocalAddress,
                   NetworkSubscriptionTracers (..), NodeToClientProtocols (..), TraceSendRecv,
                   WithAddr (..), localSnocket, localTxSubmissionPeerNull, networkErrorPolicies,
                   withIOManager)
import qualified Ouroboros.Network.NodeToClient.Version as Network
import           Ouroboros.Network.Point (withOrigin)
import qualified Ouroboros.Network.Point as Point

import           Ouroboros.Network.Protocol.ChainSync.ClientPipelined
                   (ChainSyncClientPipelined (..), ClientPipelinedStIdle (..),
                   ClientPipelinedStIntersect (..), ClientStNext (..), chainSyncClientPeerPipelined,
                   recvMsgIntersectFound, recvMsgIntersectNotFound, recvMsgRollBackward,
                   recvMsgRollForward)
import           Ouroboros.Network.Protocol.ChainSync.PipelineDecision (MkPipelineDecision,
                   PipelineDecision (..), pipelineDecisionLowHighMark, runPipelineDecision)
import           Ouroboros.Network.Protocol.ChainSync.Type (ChainSync)
import           Ouroboros.Network.Protocol.LocalStateQuery.Client (localStateQueryClientPeer)
import qualified Ouroboros.Network.Snocket as Snocket
import           Ouroboros.Network.Subscription (SubscriptionTrace)

import           Prelude (String)
import qualified Prelude

import           System.Directory (createDirectoryIfMissing)
import qualified System.Metrics.Prometheus.Metric.Gauge as Gauge

runValidator :: ValidatorParameters -> IO ()
runValidator params = do
  withIOManager $ \ iomgr -> do
    enc <- readDbSyncNodeConfig (vpConfigFile params)
    block <- DB.runDbNoLogging DB.queryLatestBlock
    genCfg <- orDie renderDbSyncNodeError $ readCardanoGenesisConfig enc
--    state <- getLatestLedgerState genCfg (vpLedgerStateDir params)
    ledgerTip <- withOriginFromMaybe . listToMaybe <$> listLedgerStateSlotNos (vpLedgerStateDir params)
    return ()
  return ()

data ValidatorParameters = ValidatorParameters
  { vpConfigFile :: !ConfigFile
  , vpLedgerStateDir :: !LedgerStateDir
  , vpAddressUtxo :: Maybe Address
  , vpRollBackDB :: Bool
  , vpRollBackLedger :: Bool
  }

type Address = ByteString

validateTips :: ValidatorParameters -> GenesisConfig -> Block -> WithOrigin SlotNo -> IO ()
validateTips p@ValidatorParameters{..} genCfg block ledgerTip = do
    stateTip <- getTip $ clsState state
--    let stSlotNo = getTipSlot $
    case compare ledgerTip (at $ blkSlotNo block) of
      LT ->
        if vpRollBackDB then do
          void $ DB.runDbNoLogging $ DB.deleteCascadeSlotNo stSlotNo
          go Nothing
        else do
          putStrLn "The ledger state is behind the db. You can enable --db-rollback to rollback."
      GT ->
        if vpRollBackLedger then do
          go $ Just $ blkSlotNo block
        else
          putStrLn "The db is behind the ledger state. You can enable --ledger-rollback to allow the ledger to rollback and proceed with validation."
      EQ -> go Nothing
  where
    go sl = do
      state <- getLatestLedgerState genCfg (vpLedgerStateDir p) (blkSlotNo block)
      let stPoint = getTip $ clsState state
      let dbPoint =
      queryUtxoAtBlockId


getBalanceLedger :: Address -> CardanoLedgerState -> _
getBalanceLedger addr st =
  case hardForkLedgerStatePerEra $ ledgerState $ clsState st of
    LedgerStateByron st -> cvsUtxo $ byronLedgerState st
    LedgerStateShelley st -> _utxoState $ esLState $ nesEs $ shelleyLedgerState $ st
    LedgerStateAllegra st -> undefined
    LedgerStateMary st -> undefined

cmpWithSlot :: SlotNo -> WithOrigin SlotNo -> Bool
cmpWithSlot sl Origin = False
cmpWithSlot sl (WithOrigin sl') = sl < sl'
