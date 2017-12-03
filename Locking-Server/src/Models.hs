{-# LANGUAGE DeriveGeneric              #-}
{-# LANGUAGE EmptyDataDecls             #-}
{-# LANGUAGE FlexibleContexts           #-}
{-# LANGUAGE FlexibleInstances          #-}
{-# LANGUAGE GADTs                      #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE MultiParamTypeClasses      #-}
{-# LANGUAGE OverloadedStrings          #-}
{-# LANGUAGE QuasiQuotes                #-}
{-# LANGUAGE RecordWildCards            #-}
{-# LANGUAGE TemplateHaskell            #-}
{-# LANGUAGE TypeFamilies               #-}

module Models where

import Control.Monad.Reader (MonadIO, MonadReader, asks, liftIO)
import Data.Aeson           (FromJSON, ToJSON)
import Database.Persist.Sql (SqlPersistT, runMigration, runSqlPool)
import Database.Persist.TH  (mkMigrate, mkPersist, persistLowerCase,
                                       share, sqlSettings)
import GHC.Generics         (Generic)
import Config               
import Data.Text            (Text)
import Data.Time

type RequestId = Int

data LockInfo = LockInfo {
  path :: String,
  position :: Int,
  locked :: Bool
}deriving(Generic)
instance ToJSON LockInfo
instance FromJSON LockInfo

share [mkPersist sqlSettings, mkMigrate "migrateAll"] [persistLowerCase|
LockQueue json
    filePath String
    queue [RequestId]
    UniqueFile filePath 
|]

doMigrations :: SqlPersistT IO ()
doMigrations = runMigration migrateAll

runDB :: (MonadReader Config m, MonadIO m) => SqlPersistT IO b -> m b
runDB query = do
  p <- asks pool
  liftIO $ runSqlPool query p
