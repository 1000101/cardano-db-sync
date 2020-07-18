{-# LANGUAGE DataKinds #-}
module Cardano.DbSync.Types
  ( CardanoBlockTip (..)
  , CardanoPoint (..)
  , ConfigFile (..)
  , DbSyncEnv (..)
  , DbSyncNodeParams (..)
  , ShelleyAddress
  , ShelleyDCert
  , ShelleyDelegCert
  , ShelleyHash
  , ShelleyMIRCert
  , ShelleyPoolCert
  , ShelleyPoolParams
  , ShelleyRewardAccount
  , ShelleyStakeCreds
  , ShelleyStakePoolKeyHash
  , ShelleyStakingCred
  , ShelleyStakingKeyHash
  , ShelleyTx
  , ShelleyTxBody
  , ShelleyTxId
  , ShelleyTxIn
  , ShelleyTxOut
  , ShelleyTxSeq
  , SocketPath (..)
  ) where

import           Cardano.Db (MigrationDir (..))
import           Cardano.DbSync.Config

import           Cardano.Slotting.Slot (SlotNo (..))

import           Ouroboros.Consensus.BlockchainTime.WallClock.Types (SystemStart)
import           Ouroboros.Consensus.Byron.Ledger (ByronBlock (..))
import           Ouroboros.Consensus.Cardano.Block (CardanoBlock)
import qualified Ouroboros.Consensus.Shelley.Ledger.Block as Shelley
import           Ouroboros.Consensus.Shelley.Protocol (TPraosStandardCrypto)
import qualified Ouroboros.Consensus.Shelley.Protocol as Shelley

import           Ouroboros.Network.Block (Point (..))
import           Ouroboros.Network.Magic (NetworkMagic (..))

import qualified Shelley.Spec.Ledger.Address as Shelley
import qualified Shelley.Spec.Ledger.BaseTypes as Shelley
import qualified Shelley.Spec.Ledger.BlockChain as Shelley
import qualified Shelley.Spec.Ledger.Credential as Shelley
import qualified Shelley.Spec.Ledger.Keys as Shelley
import qualified Shelley.Spec.Ledger.Tx as Shelley
import qualified Shelley.Spec.Ledger.TxData as Shelley


-- No longer contains a Tip value because the Tip value was useless.
data CardanoBlockTip
  = ByronBlockTip !ByronBlock
  | ShelleyBlockTip !(Shelley.ShelleyBlock TPraosStandardCrypto)
  | CardanoBlockTip !(CardanoBlock TPraosStandardCrypto)

data CardanoPoint
  = ByronPoint !(Point ByronBlock)
  | ShelleyPoint !(Point (Shelley.ShelleyBlock TPraosStandardCrypto))
  | CardanoPoint !(Point (CardanoBlock TPraosStandardCrypto))

newtype ConfigFile = ConfigFile
  { unConfigFile :: FilePath
  }

-- | The product type of all command line arguments
data DbSyncNodeParams = DbSyncNodeParams
  { enpConfigFile :: !ConfigFile
  , enpSocketPath :: !SocketPath
  , enpMigrationDir :: !MigrationDir
  , enpMaybeRollback :: !(Maybe SlotNo)
  }

data DbSyncEnv = DbSyncEnv
  { envProtocol :: !DbSyncProtocol
  , envNetwork :: !Shelley.Network
  , envNetworkMagic :: !NetworkMagic
  , envSystemStart :: !SystemStart
  }

type ShelleyAddress = Shelley.Addr Shelley.TPraosStandardCrypto
-- type ShelleyBlock = Shelley.ShelleyBlock Shelley.TPraosStandardCrypto
type ShelleyDCert = Shelley.DCert Shelley.TPraosStandardCrypto
type ShelleyDelegCert = Shelley.DelegCert Shelley.TPraosStandardCrypto
type ShelleyHash = Shelley.ShelleyHash Shelley.TPraosStandardCrypto
type ShelleyMIRCert = Shelley.MIRCert Shelley.TPraosStandardCrypto
type ShelleyPoolCert = Shelley.PoolCert Shelley.TPraosStandardCrypto
type ShelleyPoolParams = Shelley.PoolParams Shelley.TPraosStandardCrypto
type ShelleyRewardAccount = Shelley.RewardAcnt Shelley.TPraosStandardCrypto
type ShelleyStakeCreds = Shelley.StakeCreds Shelley.TPraosStandardCrypto
type ShelleyStakingCred = Shelley.StakeCredential Shelley.TPraosStandardCrypto
type ShelleyStakingKeyHash = Shelley.KeyHash 'Shelley.Staking Shelley.TPraosStandardCrypto
type ShelleyStakePoolKeyHash = Shelley.KeyHash 'Shelley.StakePool Shelley.TPraosStandardCrypto
type ShelleyTx = Shelley.Tx Shelley.TPraosStandardCrypto
type ShelleyTxBody = Shelley.TxBody Shelley.TPraosStandardCrypto
type ShelleyTxId = Shelley.TxId Shelley.TPraosStandardCrypto
type ShelleyTxIn = Shelley.TxIn Shelley.TPraosStandardCrypto
type ShelleyTxOut = Shelley.TxOut Shelley.TPraosStandardCrypto
type ShelleyTxSeq = Shelley.TxSeq Shelley.TPraosStandardCrypto

newtype SocketPath = SocketPath
  { unSocketPath :: FilePath
  }
