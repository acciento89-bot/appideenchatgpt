// Simulator-only screenshot entry; never used by the signed Store build.
import React, { useState, useEffect } from 'react';
import { SafeAreaView, View, StyleSheet } from 'react-native';
import { StatusBar } from 'expo-status-bar';
import { WorldScreen } from './src/screens/WorldScreen';
import { GameScreen } from './src/screens/GameScreen';
import { categories } from './src/data/learningContent';
import { createEmptyProgress } from './src/data/progress';
const cases = ['de','en'].flatMap(language => [
 {type:'world',language}, {type:'world',language,bottom:true},
 {type:'time',language,age:'adventurer',stage:7},
 {type:'nature',language,age:'discoverer',stage:1},
 {type:'shapes',language,age:'discoverer',stage:1,unique:true},
]);
export default function StoreCapture() {
 const [index,setIndex]=useState(0); const c=cases[index];
 useEffect(()=>{const timer=setInterval(()=>setIndex(i=>Math.min(i+1,cases.length-1)),20000);return()=>clearInterval(timer);},[]);
 const profile={id:'store-preview',nickname:'Alex',avatar:'🦊',createdAt:'',ageGroup:'discoverer',progress:createEmptyProgress()};
 let category=categories.find(x=>x.id===c.type);
 if(c.unique){category={...category,questionsByAge:{...category.questionsByAge,discoverer:[category.questionsByAge.discoverer[1],category.questionsByAge.discoverer[0],...category.questionsByAge.discoverer.slice(2)]}};}
 return <SafeAreaView style={styles.safe}><StatusBar style="dark"/><View key={index} style={styles.frame}>
 {c.type==='world'?<WorldScreen captureAtEnd={c.bottom} language={c.language} profile={profile} premiumUnlocked={false} onLanguageChange={()=>{}} onCategoryPress={()=>{}} onParentsPress={()=>{}} onProfilePress={()=>{}}/>:<GameScreen category={category} stage={c.stage} ageGroup={c.age} language={c.language} onBack={()=>{}} onCompleted={()=>{}} onNextStage={()=>{}}/>}
 </View></SafeAreaView>;
}
const styles=StyleSheet.create({safe:{flex:1,backgroundColor:'#FFF8E8'},frame:{flex:1,width:'100%',maxWidth:900,alignSelf:'center'}});
