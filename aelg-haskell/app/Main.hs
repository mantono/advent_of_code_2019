module Main
    ( main
    )
where

import           Data.ByteString.Char8          ( pack
                                                , unpack
                                                )
import           Data.CaseInsensitive           ( mk )
import qualified Data.Map                      as M
import           Data.Maybe
import           Network.HTTP.Client
import           Network.HTTP.Client.TLS
import           System.Environment
import           System.Directory
import           Control.Exception
import           Control.Concurrent.ParallelIO.Global

import qualified SolutionLookup

getSolution x = M.findWithDefault notImplemented x SolutionLookup.solutions

solve :: Integer -> ([String] -> (String, String)) -> IO String -> IO String
solve x f s = do
    (a1, a2) <- f . lines <$> s
    return
        ("Day " ++ show x ++ ":\n" ++ "  " ++ a1 ++ "\n" ++ "  " ++ a2 ++ "\n")

notImplemented s = ("Not implemented", "Input: " ++ unlines s)

createCacheDir = createDirectoryIfMissing False ".cache"

cacheName ms = ".cache/input-" ++ show ms ++ ".txt"

readInput :: String -> Integer -> IO String
readInput session dayNumber =
    try cache >>= either (const download :: IOException -> IO String) return
  where
    download = do
        initRequest <-
            parseRequest
            $  "http://adventofcode.com/2019/day/"
            ++ show dayNumber
            ++ "/input"
        let session' = "session=" ++ session
            req      = initRequest
                { requestHeaders = [(mk $ pack "Cookie", pack session')]
                }
        manager <- newTlsManager
        s       <- withResponse req manager (brConsume . responseBody)
        let input = concatMap unpack s
        writeFile (cacheName dayNumber) input
        return input
    cache = do
        createCacheDir
        readFile $ cacheName dayNumber

maybeRead = fmap fst . listToMaybe . reads

main :: IO ()
main = do
    arg        <- fmap listToMaybe getArgs
    sessionKey <- fmap (head . lines) . readFile $ "sessionKey.txt"
    let mDayNumber = arg >>= maybeRead
        s          = readInput sessionKey
        inputs     = map s (M.keys SolutionLookup.solutions)
        solvers    = case mDayNumber of
            Just x -> [solve x (getSolution x) $ inputs !! fromInteger (x - 1)]
            _      -> map (\(x, input) -> solve x (getSolution x) input)
                          (zip [1 ..] inputs)
    parallel solvers >>= mapM_ putStr
    stopGlobalPool
