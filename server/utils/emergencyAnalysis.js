// Comprehensive Emergency keyword detection and analysis - Multi-language support
const EMERGENCY_KEYWORDS = {
  help: {
    keywords: [
      // English
      'help', 'help me', 'assistance', 'emergency', 'crisis', 'urgent', 'please help',
      'somebody help', 'someone help', 'i need help', 'get help', 'call for help',
      // Hindi/Hinglish
      'help', 'हेल्प', 'मदद', 'मदद करो', 'बचाओ', 'emergency', 'इमरजेंसी',
      'urgent', 'अर्जेंट', 'please help', 'प्लीज हेल्प', 'कोई मदद करो',
      // Spanish
      'ayuda', 'ayúdame', 'socorro', 'emergencia', 'urgente', 'por favor ayuda',
      // French
      'aide', 'aidez-moi', 'secours', 'urgence', 'aidez',
      // German
      'hilfe', 'hilf mir', 'notfall', 'dringend'
    ],
    weight: 1.0
  },
  medical: {
    keywords: [
      // English
      'hurt', 'injured', 'bleeding', 'pain', 'sick', 'ambulance', 'hospital', 'doctor',
      'heart attack', 'stroke', 'unconscious', 'breathing', 'chest pain', 'seizure',
      'allergic reaction', 'overdose', 'poisoned', 'diabetic', 'broken bone', 'fracture',
      'cut', 'wound', 'burns', 'fever', 'choking', 'cant breathe', 'difficulty breathing',
      'medical emergency', 'call 911', 'paramedic', 'first aid', 'dying', 'dead',
      // Hindi/Hinglish
      'दर्द', 'pain', 'पेन', 'घायल', 'injured', 'इंजर्ड', 'खून', 'bleeding', 'ब्लीडिंग',
      'बीमार', 'sick', 'सिक', 'अस्पताल', 'hospital', 'हॉस्पिटल', 'डॉक्टर', 'doctor', 'डॉक्टर',
      'एम्बुलेंस', 'ambulance', 'सांस', 'breathing', 'ब्रीदिंग', 'heart attack', 'हार्ट अटैक',
      // Spanish
      'dolor', 'herido', 'sangrado', 'enfermo', 'ambulancia', 'hospital', 'doctor',
      'ataque cardíaco', 'respiración', 'no puedo respirar',
      // French
      'douleur', 'blessé', 'saignement', 'malade', 'ambulance', 'hôpital', 'docteur',
      'crise cardiaque', 'respiration'
    ],
    weight: 1.0
  },
  fire: {
    keywords: [
      // English
      'fire', 'smoke', 'burning', 'flames', 'fire department', 'house fire', 'building fire',
      'explosion', 'gas leak', 'smoke alarm', 'fire alarm', 'evacuation', 'evacuate',
      'burned', 'fire emergency', 'call fire department',
      // Hindi/Hinglish
      'आग', 'fire', 'फायर', 'धुआं', 'smoke', 'स्मोक', 'जल रहा', 'burning', 'बर्निंग',
      'explosion', 'एक्सप्लोजन', 'विस्फोट', 'gas leak', 'गैस लीक',
      // Spanish
      'fuego', 'humo', 'quemando', 'llamas', 'explosión', 'escape de gas',
      // French
      'feu', 'fumée', 'brûlant', 'flammes', 'explosion', 'fuite de gaz'
    ],
    weight: 1.0
  },
  police: {
    keywords: [
      // English
      'police', 'robbery', 'theft', 'attack', 'violence', 'danger', 'threatening',
      'burglar', 'intruder', 'break in', 'breaking in', 'assault', 'murder', 'rape',
      'kidnapping', 'abduction', 'domestic violence', 'abuse', 'gun', 'weapon', 'knife',
      'shooting', 'shot', 'stabbing', 'call police', 'call cops', '911',
      // Hindi/Hinglish
      'पुलिस', 'police', 'पुलिस', 'चोरी', 'robbery', 'रॉबरी', 'हमला', 'attack', 'अटैक',
      'खतरा', 'danger', 'डेंजर', 'हिंसा', 'violence', 'वायलेंस', 'बंदूक', 'gun', 'गन',
      'चाकू', 'knife', 'नाइफ', 'shooting', 'शूटिंग',
      // Spanish
      'policía', 'robo', 'ataque', 'violencia', 'peligro', 'arma', 'pistola',
      'cuchillo', 'disparo',
      // French
      'police', 'vol', 'attaque', 'violence', 'danger', 'arme', 'pistolet',
      'couteau', 'tir'
    ],
    weight: 1.0
  },
  accident: {
    keywords: [
      // English
      'accident', 'crash', 'collision', 'trapped', 'stuck', 'car accident', 'vehicle accident',
      'motorcycle accident', 'bike accident', 'hit by car', 'run over', 'rollover',
      'head on collision', 'rear ended', 'side impact', 'fallen', 'fell down', 'slip and fall',
      // Hindi/Hinglish
      'एक्सीडेंट', 'accident', 'दुर्घटना', 'crash', 'क्रैश', 'collision', 'कॉलिजन',
      'फंसा', 'trapped', 'ट्रैप्ड', 'car accident', 'कार एक्सीडेंट', 'गिरा', 'fallen', 'फॉलन',
      // Spanish
      'accidente', 'choque', 'colisión', 'atrapado', 'accidente de coche',
      'caído', 'resbaló',
      // French
      'accident', 'crash', 'collision', 'coincé', 'accident de voiture',
      'tombé', 'glissé'
    ],
    weight: 1.0
  },
  natural_disaster: {
    keywords: [
      // English
      'earthquake', 'tornado', 'hurricane', 'flood', 'flooding', 'wildfire', 'landslide',
      'avalanche', 'tsunami', 'storm', 'severe weather', 'lightning strike', 'hail',
      'tornado warning', 'hurricane warning', 'evacuation order',
      // Hindi/Hinglish
      'भूकंप', 'earthquake', 'अर्थक्वेक', 'बाढ़', 'flood', 'फ्लड', 'तूफान', 'storm', 'स्टॉर्म',
      'tsunami', 'सुनामी', 'आंधी', 'hurricane', 'हरिकेन',
      // Spanish
      'terremoto', 'tornado', 'huracán', 'inundación', 'tormenta', 'tsunami',
      // French
      'tremblement de terre', 'tornade', 'ouragan', 'inondation', 'tempête', 'tsunami'
    ],
    weight: 1.0
  },
  violence: {
    keywords: [
      // English
      'fighting', 'fight', 'punching', 'hitting', 'beating', 'attacked', 'mugged',
      'threatened', 'stalker', 'harassment', 'bullying', 'violent', 'aggressive',
      // Hindi/Hinglish
      'लड़ाई', 'fight', 'फाइट', 'मारपीट', 'beating', 'बीटिंग', 'हमला', 'attacked', 'अटैक्ड',
      'धमकी', 'threatened', 'थ्रेटन्ड', 'हिंसक', 'violent', 'वायलेंट',
      // Spanish
      'pelea', 'golpeando', 'atacado', 'amenazado', 'violento', 'agresivo',
      // French
      'bagarre', 'frapper', 'attaqué', 'menacé', 'violent', 'agressif'
    ],
    weight: 0.8
  },
  distress: {
    keywords: [
      // English
      'scared', 'afraid', 'terrified', 'panic', 'desperate', 'trapped', 'lost',
      'missing', 'cant find', 'stranded', 'isolated', 'alone', 'frightened',
      // Hindi/Hinglish
      'डरा', 'scared', 'स्केयर्ड', 'घबराया', 'panic', 'पैनिक', 'परेशान', 'desperate', 'डेस्परेट',
      'खो गया', 'lost', 'लॉस्ट', 'अकेला', 'alone', 'अलोन', 'डरा हुआ', 'frightened', 'फ्राइटन्ड',
      // Spanish
      'asustado', 'miedo', 'pánico', 'desesperado', 'perdido', 'solo', 'aterrorizado',
      // French
      'effrayé', 'peur', 'panique', 'désespéré', 'perdu', 'seul', 'terrifié'
    ],
    weight: 0.7
  }
};

// Stress and panic indicators - Multi-language
const STRESS_INDICATORS = [
  // English
  'please', 'somebody', 'anyone', 'quickly', 'fast', 'hurry', 'now', 'immediately',
  'scared', 'afraid', 'terrified', 'panic', 'desperate', 'oh no', 'oh god', 'my god',
  'what do i do', 'i dont know what to do', 'losing consciousness', 'getting worse',
  'getting weaker', 'cant move', 'cant feel', 'going numb', 'very bad', 'really bad',
  'serious', 'critical', 'life threatening', 'gonna die', 'going to die',
  // Hindi/Hinglish
  'प्लीज', 'please', 'कोई', 'somebody', 'जल्दी', 'quickly', 'क्विकली', 'तुरंत', 'immediately', 'इमीडिएटली',
  'डरा', 'scared', 'स्केयर्ड', 'घबराया', 'panic', 'पैनिक', 'परेशान', 'desperate', 'डेस्परेट',
  'अरे नहीं', 'oh no', 'ओह नो', 'भगवान', 'oh god', 'ओह गॉड', 'क्या करूं', 'what do i do',
  'बहुत बुरा', 'very bad', 'वेरी बैड', 'गंभीर', 'serious', 'सीरियस', 'मरने वाला', 'gonna die',
  // Spanish
  'por favor', 'alguien', 'rápidamente', 'rápido', 'ahora', 'inmediatamente',
  'asustado', 'miedo', 'pánico', 'desesperado', 'dios mío', 'muy malo', 'serio',
  // French
  'sil vous plaît', 'quelquun', 'rapidement', 'vite', 'maintenant', 'immédiatement',
  'effrayé', 'peur', 'panique', 'désespéré', 'mon dieu', 'très mauvais', 'sérieux'
];

function analyzeForEmergency(text) {
  if (!text || typeof text !== 'string') {
    return {
      isEmergency: false,
      type: null,
      confidence: 0,
      keywords: []
    };
  }

  const lowerText = text.toLowerCase();
  const words = lowerText.split(/\s+/);
  
  let totalScore = 0;
  let detectedKeywords = [];
  let emergencyTypes = [];
  
  // Check for emergency keywords
  Object.entries(EMERGENCY_KEYWORDS).forEach(([type, data]) => {
    const typeScore = data.keywords.reduce((score, keyword) => {
      if (lowerText.includes(keyword)) {
        detectedKeywords.push(keyword);
        return score + data.weight;
      }
      return score;
    }, 0);
    
    if (typeScore > 0) {
      emergencyTypes.push({ type, score: typeScore });
      totalScore += typeScore;
    }
  });
  
  // Check for stress indicators
  const stressScore = STRESS_INDICATORS.reduce((score, indicator) => {
    return lowerText.includes(indicator) ? score + 0.3 : score;
  }, 0);
  
  totalScore += stressScore;
  
  // Add stress indicators to keywords if found
  STRESS_INDICATORS.forEach(indicator => {
    if (lowerText.includes(indicator)) {
      detectedKeywords.push(indicator);
    }
  });
  
  // Check for repetition (indicates urgency)
  const uniqueWords = new Set(words);
  const repetitionRatio = 1 - (uniqueWords.size / words.length);
  if (repetitionRatio > 0.3) { // High repetition
    totalScore += 0.5;
  }
  
  // Check for short, urgent phrases
  if (words.length <= 5 && totalScore > 0) {
    totalScore += 0.3;
  }
  
  // Determine primary emergency type
  const primaryType = emergencyTypes.reduce((prev, current) => {
    return (current.score > prev.score) ? current : prev;
  }, { type: null, score: 0 });
  
  // Calculate confidence (normalize score)
  const confidence = Math.min(totalScore / 2.5, 1); // More sensitive threshold
  const isEmergency = confidence >= 0.3; // Lower threshold for emergency detection
  
  return {
    isEmergency,
    type: isEmergency ? primaryType.type : null,
    confidence: Math.round(confidence * 100) / 100,
    keywords: [...new Set(detectedKeywords)]
  };
}

// Test function for emergency analysis
function testEmergencyAnalysis() {
  const testCases = [
    "Help me please, I'm hurt!",
    "There's a fire in my house!",
    "I need help, someone attacked me",
    "Hello, how are you today?",
    "Help help help I'm trapped!",
    "Emergency! Car accident on highway!",
    "I'm having a heart attack, call ambulance!"
  ];
  
  testCases.forEach(text => {
    const result = analyzeForEmergency(text);
    // Test results can be logged to console if needed for debugging
  });
}

module.exports = {
  analyzeForEmergency,
  testEmergencyAnalysis,
  EMERGENCY_KEYWORDS,
  STRESS_INDICATORS
};