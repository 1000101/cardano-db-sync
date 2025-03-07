{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Test.IO.Cardano.Db.Util
  ( assertBool
  , deleteAllBlocksCascade
  , dummyUTCTime
  , mkAddressHash
  , mkBlock
  , mkBlockHash
  , mkMerkelRoot
  , mkTxHash
  , mkTxs
  , mkTxOut
  , testSlotLeader
  , unBlockId
  , unTxId
  ) where

import           Control.Monad (unless)
import           Control.Monad.IO.Class (MonadIO, liftIO)
import           Control.Monad.Trans.Reader (ReaderT)

import           Data.ByteString.Char8 (ByteString)
import qualified Data.ByteString.Char8 as BS
import qualified Data.Text as Text
import           Data.Time.Calendar (Day (..))
import           Data.Time.Clock (UTCTime (..))
import           Data.Word (Word64)

import           Database.Persist.Sql (SqlBackend, delete, selectKeysList)

import           Cardano.Db

import           Text.Printf (printf)


assertBool :: MonadIO m => String -> Bool -> m ()
assertBool msg bool =
  liftIO $ unless bool (error msg)

deleteAllBlocksCascade :: MonadIO m => ReaderT SqlBackend m ()
deleteAllBlocksCascade = do
  (keys :: [BlockId]) <- selectKeysList [] []
  mapM_ delete keys

dummyUTCTime :: UTCTime
dummyUTCTime = UTCTime (ModifiedJulianDay 0) 0

mkAddressHash :: BlockId -> TxId -> String
mkAddressHash blkId txId =
  take 28 $ printf "tx out #%d, tx #%d" (unBlockId blkId) (unTxId txId) ++ replicate 28 ' '

mkBlock :: Word64 -> SlotLeaderId -> Block
mkBlock blk slid =
  Block
    { blockHash = mkBlockHash blk
    , blockEpochNo = Just 0
    , blockSlotNo = Just 0
    , blockEpochSlotNo = Nothing
    , blockBlockNo = Nothing
    , blockPreviousId = Nothing
    , blockMerkelRoot = Nothing
    , blockSlotLeaderId = slid
    , blockSize = 42
    , blockTime = dummyUTCTime
    , blockTxCount = 0
    , blockProtoMajor = 1
    , blockProtoMinor = 0
    , blockVrfKey = Nothing
    , blockOpCert = Nothing
    }


mkBlockHash :: Word64 -> ByteString
mkBlockHash blkId =
  BS.pack (take 32 $ printf "block #%d" blkId ++ replicate 32 ' ')

mkMerkelRoot :: Word64 -> ByteString
mkMerkelRoot blkId =
  BS.pack (take 32 $ printf "merkel root #%d" blkId ++ replicate 32 ' ')

mkTxHash :: BlockId -> Word64 -> ByteString
mkTxHash blk tx =
  BS.pack (take 32 $ printf "block #%d, tx #%d" (unBlockId blk) tx ++ replicate 32 ' ')

mkTxs :: BlockId -> Word -> [Tx]
mkTxs blkId count =
    take (fromIntegral count) $ map create [ 0 .. ]
  where
    create w =
      Tx
        { txHash = mkTxHash blkId w
        , txBlockId = blkId
        , txBlockIndex = 0
        , txOutSum = DbLovelace 2
        , txFee = DbLovelace 1
        , txDeposit = 0
        , txSize = 12
        , txInvalidHereafter = Nothing
        , txInvalidBefore = Nothing
        }

testSlotLeader :: SlotLeader
testSlotLeader =
  SlotLeader (BS.pack . take 28 $ "test slot leader" ++ replicate 28 ' ') Nothing "Dummy test slot leader"

mkTxOut :: BlockId -> TxId -> TxOut
mkTxOut blkId txId =
  let addr = mkAddressHash blkId txId in
  TxOut txId 0 (Text.pack addr) (BS.pack addr) Nothing Nothing (DbLovelace 1000000000)
