{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE OverloadedLists #-}
{-# LANGUAGE RecordWildCards #-}

module Main where

import Test
import qualified TestImport
import Test.Tasty
import Test.Tasty.HUnit ((@?=), testCase)
import Control.Applicative
import Control.Monad
import Proto3.Suite
import qualified Data.ByteString.Char8 as BC
import System.IO
import System.Exit

main :: IO ()
main = do putStr "\n"
          defaultMain tests

tests, testCase1, testCase2, testCase3, testCase4, testCase5,
    testCase6, testCase8, testCase9, testCase10, testCase11,
    testCase12, testCase13, testCase14, testCase15 :: TestTree
tests = testGroup "Decode protobuf messages from Python"
          [  testCase1,  testCase2,  testCase3,  testCase4
          ,  testCase5,  testCase6,  testCase7,  testCase8
          ,  testCase9, testCase10, testCase11, testCase12
          , testCase13, testCase14, testCase15, testCase16 ]

readProto :: Message a => IO a
readProto = do length <- readLn
               res <- fromByteString <$> BC.hGet stdin length
               case res of
                 Left err -> fail ("readProto: " ++ show err)
                 Right  x -> pure x

testCase1  = testCase "Trivial message" $
    do Trivial { .. } <- readProto

       trivialTrivialField @?= 0x7BADBEEF

testCase2  = testCase "Multi-field message" $
    do MultipleFields { .. } <- readProto

       multipleFieldsMultiFieldDouble @?= 1.125
       multipleFieldsMultiFieldFloat  @?= 1e9
       multipleFieldsMultiFieldInt32  @?= 0x1135
       multipleFieldsMultiFieldInt64  @?= 0x7FFAFABADDEAFFA0
       multipleFieldsMultiFieldString @?= "Goodnight moon"
       multipleFieldsMultiFieldBool   @?= False

testCase3  = testCase "Nested enumeration" $
    do WithEnum { withEnumEnumField = Enumerated a } <- readProto
       a @?= Right WithEnum_TestEnumENUM1

       WithEnum { withEnumEnumField = Enumerated b } <- readProto
       b @?= Right WithEnum_TestEnumENUM2

       WithEnum { withEnumEnumField = Enumerated c } <- readProto
       c @?= Right WithEnum_TestEnumENUM3

       WithEnum { withEnumEnumField = Enumerated d } <- readProto
       d @?= Left 0xBEEF

testCase4  = testCase "Nested message" $
    do WithNesting { withNestingNestedMessage = a } <- readProto
       a @?= Just (WithNesting_Nested "testCase4 nestedField1" 0x1010)

       WithNesting { withNestingNestedMessage = b } <- readProto
       b @?= Nothing

testCase5  = testCase "Nested repeated message" $
    do WithNestingRepeated { withNestingRepeatedNestedMessages = a } <- readProto
       length a @?= 3
       let [a1, a2, a3] = a

       a1 @?= WithNestingRepeated_Nested "testCase5 nestedField1" 0xDCBA [5, 3, 2, 1, 1] [0xBADBEEF, 0x40302001, 0xACBA, 3]
       a2 @?= WithNestingRepeated_Nested "Hello world" 0x7FFFFFFF [0, 0, 0] []
       a3 @?= WithNestingRepeated_Nested "" 0 [] []

       WithNestingRepeated { withNestingRepeatedNestedMessages = b } <- readProto
       b @?= []

testCase6  = testCase "Nested repeated int message" $
    do WithNestingRepeatedInts { withNestingRepeatedIntsNestedInts = a } <- readProto
       a @?= [ WithNestingRepeatedInts_NestedInts 636513 619021 ]

       WithNestingRepeatedInts { withNestingRepeatedIntsNestedInts = b } <- readProto
       b @?= []

       WithNestingRepeatedInts { withNestingRepeatedIntsNestedInts = c } <- readProto
       c @?= [ WithNestingRepeatedInts_NestedInts 636513 619021
             , WithNestingRepeatedInts_NestedInts 423549 687069
             , WithNestingRepeatedInts_NestedInts 545506 143731
             , WithNestingRepeatedInts_NestedInts 193605 385360 ]

testCase7  = testCase "Repeated int32 field" $
    do WithRepetition { withRepetitionRepeatedField1 = a } <- readProto
       a @?= []

       WithRepetition { withRepetitionRepeatedField1 = b } <- readProto
       b @?= [1..10000]

testCase8  = testCase "Fixed-width integer types" $
    do WithFixedTypes { .. } <- readProto
       withFixedTypesFixed1 @?= 0
       withFixedTypesFixed2 @?= 0
       withFixedTypesFixed3 @?= 0
       withFixedTypesFixed4 @?= 0

       WithFixedTypes { .. } <- readProto
       withFixedTypesFixed1 @?= maxBound
       withFixedTypesFixed2 @?= maxBound
       withFixedTypesFixed3 @?= maxBound
       withFixedTypesFixed4 @?= maxBound

       WithFixedTypes { .. } <- readProto
       withFixedTypesFixed1 @?= minBound
       withFixedTypesFixed2 @?= minBound
       withFixedTypesFixed3 @?= minBound
       withFixedTypesFixed4 @?= minBound

testCase9  = testCase "Bytes fields" $
    do WithBytes { .. } <- readProto
       withBytesBytes1 @?= "\x00\x00\x00\x01\x02\x03\xFF\xFF\x00\x01"
       withBytesBytes2 @?= ["", "\x01", "\xAB\xBAhello", "\xBB"]

       WithBytes { .. } <- readProto
       withBytesBytes1 @?= "Hello world"
       withBytesBytes2 @?= []

       WithBytes { .. } <- readProto
       withBytesBytes1 @?= ""
       withBytesBytes2 @?= ["Hello", "\x00world", "\x00\x00"]

       WithBytes { .. } <- readProto
       withBytesBytes1 @?= ""
       withBytesBytes2 @?= []

testCase10 = testCase "Packed and unpacked repeated types" $
    do WithPacking { .. } <- readProto
       withPackingPacking1 @?= []
       withPackingPacking2 @?= []

       WithPacking { .. } <- readProto
       withPackingPacking1 @?= [100, 2000, 300, 4000, 500, 60000, 7000]
       withPackingPacking2 @?= []

       WithPacking { .. } <- readProto
       withPackingPacking1 @?= []
       withPackingPacking2 @?= [100, 2000, 300, 4000, 500, 60000, 7000]

       WithPacking { .. } <- readProto
       withPackingPacking1 @?= [1, 2, 3, 4, 5]
       withPackingPacking2 @?= [5, 4, 3, 2, 1]

testCase11 = testCase "All possible packed types" $
    do a <- readProto
       a @?= AllPackedTypes [] [] [] [] [] [] [] [] [] []

       b <- readProto
       b @?= AllPackedTypes [1] [2] [3] [4] [5] [6] [7] [8] [9] [10]

       c <- readProto
       c @?= AllPackedTypes [1] [2] [-3] [-4] [5] [6] [-7] [-8] [-9] [-10]

       d <- readProto
       d @?= AllPackedTypes [1..10000] [1..10000]
                            [1..10000] [1..10000]
                            [1..10000] [1..10000]
                            [1,1.125..10000] [1,1.125..10000]
                            [1..10000] [1..10000]

testCase12 = testCase "Message with out of order field numbers" $
    do OutOfOrderFields { .. } <- readProto
       outOfOrderFieldsField1 @?= []
       outOfOrderFieldsField2 @?= ""
       outOfOrderFieldsField3 @?= maxBound
       outOfOrderFieldsField4 @?= []

       OutOfOrderFields { .. } <- readProto
       outOfOrderFieldsField1 @?= [1,7..100]
       outOfOrderFieldsField2 @?= "This is a test"
       outOfOrderFieldsField3 @?= minBound
       outOfOrderFieldsField4 @?= ["This", "is", "a", "test"]

testCase13 = testCase "Nested message with the same name as another package-level message" $
    do ShadowedMessage { .. } <- readProto
       shadowedMessageName  @?= "name"
       shadowedMessageValue @?= 0x7DADBEEF

       MessageShadower { .. } <- readProto
       messageShadowerName @?= "another name"
       messageShadowerShadowedMessage @?= Just (MessageShadower_ShadowedMessage "name" "string value")

       MessageShadower_ShadowedMessage { .. } <- readProto
       messageShadower_ShadowedMessageName  @?= "another name"
       messageShadower_ShadowedMessageValue @?= "another string"

testCase14 = testCase "Qualified name resolution" $
    do WithQualifiedName { .. } <- readProto
       withQualifiedNameQname1 @?= Just (ShadowedMessage "int value" 2)
       withQualifiedNameQname2 @?= Just (MessageShadower_ShadowedMessage "string value" "hello world")

testCase15 = testCase "Imported message resolution" $
    do TestImport.WithNesting { .. } <- readProto
       withNestingNestedMessage1 @?= Just (TestImport.WithNesting_Nested 1 2)
       withNestingNestedMessage2 @?= Nothing

testCase16 = testCase "Proper resolution of shadowed message names" $
    do UsingImported { .. } <- readProto
       usingImportedImportedNesting @?= Just (TestImport.WithNesting (Just (TestImport.WithNesting_Nested 1 2))
                                                                     (Just (TestImport.WithNesting_Nested 3 4)))
       usingImportedLocalNesting @?= Just (WithNesting (Just (WithNesting_Nested "field" 0xBEEF)))
