{-# LANGUAGE DeriveGeneric, OverloadedStrings, DuplicateRecordFields #-}

module Query where

import Solr
import Update
import Data.List
import Data.Char
import Data.Maybe

{-
The attemp is to group elements of form (?a,?ta,?b,?tb,?rel) given synsets
from portuguese related to synsets in english that sustain a relation ?rel

 - ?a and ?b are word/lexicalform
 - ?ta and ?tb are synset types
 - ?rel is a relation

see: github.com/NLP-CISUC/PT-LexicalSemantics/blob/master/OWN-PT/query.sparql
-}

data SPointer = SPointer
  { wordA :: Sense
  , wordB :: [Sense]
  , synsA :: String
  , synsB :: String
  , typeA :: RDFType
  , typeB :: RDFType
  , relation :: Relation
  } deriving (Show)

instance Eq SPointer where
  (==) x y = (==) (sPointerToTuple x) (sPointerToTuple y)

instance Ord SPointer where
  (<=) x y = (<=) (sPointerToTuple x) (sPointerToTuple y)


sPointerToTuple (SPointer a bs sa sb ta tb rel) = (a,bs,sa,sb,ta,tb,rel)
tupleToSPointer (a,bs,sa,sb,ta,tb,rel) = (SPointer a bs sa sb ta tb rel)

collectRelationsSenses :: [Synset] -> [SPointer]
collectRelationsSenses synsets =
  [ SPointer a (bs synB p) (doc_id synA) (doc_id synB) ta tb (pointer p)
  | (synA,p,synB) <- collectPointersSynsets synsets
  , a <- choseSenseWords synA (target_word p)
  , ta <- rdf_type synA
  , tb <- rdf_type synB]
   where
    bs synX p = choseSenseWords synX (target_word p)
    choseSenseWords synX Nothing = map (map toLower) $ fromMaybe [] (word_pt synX)
    choseSenseWords synX word = map (map toLower) $ [fromJust word]
  
  
collectPointersSynsets :: [Synset] -> [(Synset, Pointer, Synset)]
collectPointersSynsets synsets =
  collectSynsets [] (sortBy compareIds relationIds) (sort synsets)
  where
    compareIds x y = compare (target_synset $ snd x) (target_synset $ snd y)
    relationIds = [(s,p) | s <- synsets, p <- collectPointers s]


collectSynsets out [] _ = out
collectSynsets out (rid:rids) (syn:syns) =
  case (compare (target_synset $ snd rid) (doc_id syn)) of
    GT -> collectSynsets out (rid:rids) syns
    EQ -> collectSynsets ((fst rid, snd rid, syn):out) rids (syn:syns)


collectPointers :: Synset -> [Pointer]
collectPointers synset =
  concat $ map (fromMaybe []) $ pointers
  where
    pointers = [relation synset | relation <- relations]


-- relation fuctions
relations :: [Synset -> Maybe [Pointer]]
relations = [
  wn30_en_adjectivePertainsTo,
  wn30_en_adverbPertainsTo,
  wn30_en_antonymOf,
  wn30_en_attribute,
  wn30_en_causes,
  wn30_en_classifiedByRegion,
  wn30_en_classifiedByTopic,
  wn30_en_classifiedByUsage,
  wn30_en_classifiesByRegion,
  wn30_en_classifiesByTopic,
  wn30_en_classifiesByUsage,
  wn30_en_derivationallyRelated,
  wn30_en_hasInstance,
  wn30_en_hypernymOf,
  wn30_en_hyponymOf,
  wn30_en_instanceOf,
  wn30_en_memberHolonymOf,
  wn30_en_memberMeronymOf,
  wn30_en_partHolonymOf,
  wn30_en_partMeronymOf,
  wn30_en_participleOf,
  wn30_en_sameVerbGroupAs,
  wn30_en_seeAlso,
  wn30_en_substanceHolonymOf]
