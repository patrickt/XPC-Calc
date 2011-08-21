#! /usr/bin/env runhaskell

> import Distribution.Simple
> import Distribution.Simple.LocalBuildInfo
> import Distribution.Simple.Setup
> import Distribution.PackageDescription
> import System.Cmd

> xpcHooks :: UserHooks
> xpcHooks = simpleUserHooks {
> 	buildHook = buildWithXcode
> }

Since getting cabal to build Objective-C source is somewhat of a dicey proposition,
we are temporarily farming out to xcodebuild. This is terrible, but it works.

> buildWithXcode :: PackageDescription -> LocalBuildInfo -> UserHooks -> BuildFlags -> IO ()
> buildWithXcode _ _ _ _ = do
>   system "xcodebuild -project XPC\\ Calc.xcodeproj -alltargets"
>   return ()

> main :: IO ()
> main = defaultMainWithHooks xpcHooks