--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
import           Data.Monoid (mappend)
import           Data.Time (getCurrentTime, formatTime, defaultTimeLocale)
import           Hakyll


--------------------------------------------------------------------------------
main :: IO ()
main = do
    year <- formatTime defaultTimeLocale "%Y" <$> getCurrentTime
    hakyll $ do
        match "images/**" $ do
            route   idRoute
            compile copyFileCompiler

        match "css/*" $ do
            route   idRoute
            compile compressCssCompiler

        match (fromList ["about.rst", "contact.markdown"]) $ do
            route   $ setExtension "html"
            compile $ pandocCompiler
                >>= loadAndApplyTemplate "templates/default.html" (yearCtx year)
                >>= relativizeUrls

        match "posts/**" $ do
            route $ (gsubRoute "posts/" (const "")) `composeRoutes` (setExtension "html")
            compile $ getResourceBody
                >>= saveSnapshot "content"
                >>= loadAndApplyTemplate "templates/post.html"    (postCtx year)
                >>= relativizeUrls

        create ["archive.html"] $ do
            route idRoute
            compile $ do
                posts <- recentFirst =<< loadAll "posts/**"
                let archiveCtx =
                        listField "posts" (postCtx year) (return posts) `mappend`
                        constField "title" "Archives"            `mappend`
                        yearCtx year

                makeItem ""
                    >>= loadAndApplyTemplate "templates/archive.html" archiveCtx
                    >>= loadAndApplyTemplate "templates/default.html" archiveCtx
                    >>= relativizeUrls

        create ["atom.xml"] $ do
            route idRoute
            compile $ do
                let feedCtx = postCtx year `mappend` bodyField "description"
                posts <- fmap (take 10) . recentFirst =<<
                    loadAllSnapshots "posts/**" "content"
                renderAtom myFeedConfiguration feedCtx posts

        match "index.html" $ do
            route idRoute
            compile $ do
                posts <- recentFirst =<< loadAll "posts/**"
                let indexCtx =
                        listField "posts" (postCtx year) (return posts) `mappend`
                        constField "title" "Home"                `mappend`
                        yearCtx year

                getResourceBody
                    >>= applyAsTemplate indexCtx
                    >>= loadAndApplyTemplate "templates/default.html" indexCtx
                    >>= relativizeUrls

        match "templates/*" $ compile templateCompiler


--------------------------------------------------------------------------------
yearCtx :: String -> Context String
yearCtx year = constField "year" year `mappend` defaultContext

postCtx :: String -> Context String
postCtx year =
    dateField "atomdate" "%Y-%m-%dT%H:%M:%SZ" `mappend`
    dateField "entrydate" "%a %e %B %Y" `mappend`
    dateField "date" "%B %e, %Y" `mappend`
    yearCtx year

myFeedConfiguration :: FeedConfiguration
myFeedConfiguration = FeedConfiguration
    { feedTitle       = "Smelly Tofu"
    , feedDescription = ""
    , feedAuthorName  = "Phil Xiaojun Hu"
    , feedAuthorEmail = "phil@cnphil.com"
    , feedRoot        = "https://blog.phil.tw"
    }
