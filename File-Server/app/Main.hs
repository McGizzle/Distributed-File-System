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

module Main where

import Server
import Client
import System.Environment

import Control.Concurrent (forkIO)

import Data.Aeson           (FromJSON, ToJSON)
import Database.Persist 
import Database.Persist.Sql 
import Database.Persist.TH  
import Database.Persist.Postgresql
import           Control.Monad.IO.Class  (liftIO)
import           Control.Monad.Logger    (runStderrLoggingT)
                                       
share [mkPersist sqlSettings, mkMigrate "migrateAll"] [persistLowerCase|
FileNode json
    host String
    port Int 
    active Bool
    deriving Show
|]

connStr = "host=localhost dbname=fs_dev user=root password=root port=5432"

informNetwork :: Int -> IO ()
informNetwork port = do
  runStderrLoggingT $ withPostgresqlPool connStr 10 $ \pool -> liftIO $ do
    flip runSqlPersistMPool pool $ do
            runMigration migrateAll
            insert $ FileNode "localhost" port True
            return ()
main :: IO ()
main = do
  [port] <- getArgs
  putStrLn $ "Server is running on port: " ++ port
  runServer (read port)
  forkIO $ informNetwork (read port)
  runServer (read port)


           
