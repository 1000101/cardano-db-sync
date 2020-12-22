{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE OverloadedStrings #-}

import           Cardano.Db
import           Cardano.Db.App
import           Cardano.DbSync.Validator

import           Cardano.Slotting.Slot (SlotNo (..))

import           Control.Applicative (optional)

import           Data.Monoid ((<>))
import           Data.Word (Word64)

import           Options.Applicative (Parser, ParserInfo, ParserPrefs)
import qualified Options.Applicative as Opt

main :: IO ()
main = Opt.execParser opts >>= runCommand

opts :: ParserInfo LedgerCommand
opts = Opt.info (Opt.helper <*> pCommand)
      ( Opt.fullDesc
      <> Opt.header "cardano-db-ledger-tool - Manage the Cardano PostgreSQL Database and the ledger"
      )

pCommand :: Parser Command
pCommand =
  Opt.subparser
    ( Opt.command "validate-address"
       ( Opt.info (pValidateAddress)
          $ Opt.progDesc "Validate that the UTxO balance from the database and the ledger state match"
          )
    )

pValidateAddress :: Parser LedgerCommand
pValidateAddress =
  Validate <$> pAddress

pAddress :: Address
pAddress = undefined

runCommand :: 

data LedgerCommand
  = Validate Address

pValidateAddress