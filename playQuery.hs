{-# LANGUAGE TypeSynonymInstances #-}
{-# LANGUAGE FunctionalDependencies #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE DeriveDataTypeable #-}
import Data.UString hiding (find, sort, putStrLn)
import Database.MongoDB.Connection
import Data.Maybe (fromJust)
import Control.Monad (forM_)
import Control.Monad.Trans (liftIO)

import Data.Typeable
import Data.Bson
import Database.MongoDB.Structured
import Database.MongoDB.Structured.Deriving.TH
import Database.MongoDB.Structured.Query


data User = User { userId    :: SObjId
                 , firstName :: String
                 , lastName  :: String
                 , favNr     :: Int
                 } deriving(Show, Read, Eq, Ord, Typeable)
$(deriveStructured ''User)


insertUsers = insertMany 
  [ User { userId = noSObjId, firstName = "deian", lastName = "stefan", favNr = 3 }
  , User { userId = noSObjId, firstName = "amit" , lastName = "levy", favNr = 42 }
  , User { userId = noSObjId, firstName = "david", lastName = "mazieres", favNr = 1337 }
  ]

run = do
   delete (select ( (.*) :: QueryExp User))
   insertUsers
   let query = select (FirstName .== "deian" .|| FavNr .>= 3)
   liftIO $ print query
   users <- find query >>= rest
   liftIO $ printFunc users
    where printFunc users = forM_ users $ \u ->
            putStrLn . show $ (fromJust $ u :: User)

main = do
   pipe <- runIOE $ connect (host "127.0.0.1")
   e <- access pipe master "auth" run
   close pipe
   print e

--
--
--


data UserId = UserId deriving (Show, Eq)
instance Selectable User UserId SObjId where s _ _ = "_id"

data FirstName = FirstName deriving (Show, Eq)
instance Selectable User FirstName String where s _ _ = "firstName"

data LastName = LastName deriving (Show, Eq)
instance Selectable User LastName String where s _ _ = "lastName"

data FavNr = FavNr deriving (Show, Eq)
instance Selectable User FavNr Int where s _ _ = "favNr"


