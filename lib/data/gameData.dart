// lib/data/game_data.dart

import 'package:flutter/material.dart';

class GameData {
  // Digit to Pana mapping (Single digit keys with 9 values each)
  static const Map<String, List<String>> digitPanaMap = {
    '0': ['118', '226', '244', '299', '334', '488', '668', '677', '550'],
    '1': ['119', '155', '227', '335', '344', '399', '588', '669', '100'],
    '2': ['110', '228', '255', '336', '499', '669', '688', '778', '200'],
    '3': ['166', '229', '337', '355', '445', '599', '779', '788', '300'],
    '4': ['112', '220', '266', '338', '446', '455', '699', '770', '400'],
    '5': ['113', '122', '177', '339', '366', '447', '799', '889', '500'],
    '6': ['114', '277', '330', '448', '466', '556', '880', '899', '600'],
    '7': ['115', '133', '188', '223', '377', '449', '557', '566', '700'],
    '8': ['116', '224', '233', '288', '440', '477', '558', '990', '800'],
    '9': ['177', '144', '199', '225', '388', '559', '577', '667', '900'],
  };

  // Pana Combinations (Single digit keys with 12 values each)
  static const Map<String, List<String>> panaCombinations = {
    '0': [
      '127',
      '136',
      '145',
      '190',
      '235',
      '280',
      '370',
      '389',
      '460',
      '479',
      '569',
      '578',
    ],
    '1': [
      '128',
      '137',
      '146',
      '236',
      '245',
      '290',
      '380',
      '470',
      '489',
      '560',
      '579',
      '678',
    ],
    '2': [
      '129',
      '138',
      '147',
      '156',
      '237',
      '246',
      '346',
      '390',
      '480',
      '570',
      '589',
      '679',
    ],
    '3': [
      '120',
      '139',
      '148',
      '157',
      '238',
      '247',
      '256',
      '346',
      '490',
      '580',
      '670',
      '689',
    ],
    '4': [
      '130',
      '149',
      '158',
      '167',
      '239',
      '248',
      '257',
      '347',
      '356',
      '590',
      '680',
      '789',
    ],
    '5': [
      '140',
      '159',
      '168',
      '230',
      '249',
      '258',
      '267',
      '348',
      '357',
      '456',
      '690',
      '780',
    ],
    '6': [
      '123',
      '150',
      '169',
      '178',
      '240',
      '259',
      '268',
      '349',
      '358',
      '367',
      '457',
      '790',
    ],
    '7': [
      '124',
      '160',
      '179',
      '250',
      '269',
      '278',
      '340',
      '359',
      '368',
      '458',
      '467',
      '890',
    ],
    '8': [
      '125',
      '134',
      '170',
      '189',
      '260',
      '279',
      '350',
      '369',
      '378',
      '459',
      '468',
      '567',
    ],
    '9': [
      '126',
      '135',
      '180',
      '234',
      '270',
      '289',
      '360',
      '379',
      '450',
      '469',
      '478',
      '568',
    ],
  };

  // Triple Pana Combinations (All triple digits)
  static const List<String> triplePanaCombinations = [
    '000',
    '111',
    '222',
    '333',
    '444',
    '555',
    '666',
    '777',
    '888',
    '999',
  ];

  // Family Pana mapping (Three-digit keys with variable number of values)
  static const Map<String, List<String>> familyPana = {
    '111': ['111', '116', '155', '166', '666'],
    '112': ['112', '117', '126', '167', '266', '677'],
    '113': ['113', '118', '136', '168', '366', '668'],
    '114': ['114', '119', '146', '169', '466', '669'],
    '115': ['115', '110', '156', '160', '566', '660'],
    '122': ['122', '127', '177', '226', '267', '677'],
    '123': ['123', '128', '137', '178', '236', '268', '367', '678'],
    '124': ['124', '129', '147', '179', '246', '269', '467', '679'],
    '125': ['125', '120', '157', '170', '256', '260', '567', '670'],
    '133': ['133', '138', '188', '336', '368', '688'],
    '134': ['134', '139', '148', '189', '346', '369', '468', '689'],
    '135': ['135', '130', '128', '180', '356', '360', '568', '680'],
    '144': ['144', '149', '199', '446', '469', '699'],
    '145': ['145', '145', '159', '190', '456', '460', '569', '690'],
    '155': ['155', '100', '150', '556', '560', '600'],
    '222': ['222', '227', '277', '777'],
    '223': ['223', '228', '237', '278', '377', '778'],
    '224': ['224', '229', '247', '279', '477', '779'],
    '225': ['225', '220', '257', '270', '577', '770'],
    '233': ['233', '238', '288', '337', '378', '788'],
    '234': ['234', '239', '248', '289', '347', '379', '478', '789'],
    '235': ['235', '230', '258', '280', '357', '370', '578', '780'],
    '244': ['244', '249', '299', '447', '479', '799'],
    '245': ['245', '240', '259', '290', '457', '470', '579', '790'],
    '255': ['255', '200', '250', '257', '570', '700'],
    '333': ['333', '338', '388', '888'],
    '334': ['334', '339', '348', '389', '488', '889'],
    '335': ['335', '330', '358', '380', '588', '880'],
    '344': ['344', '349', '399', '448', '489', '899'],
    '345': ['345', '340', '359', '390', '458', '480', '589', '890'],
    '355': ['355', '300', '350', '558', '580', '800'],
    '444': ['444', '449', '499', '999'],
    '445': ['445', '440', '459', '490', '599', '990'],
    '455': ['455', '400', '450', '559', '590', '900'],
    '555': ['555', '000', '500', '550'],
  };

  // Cycle Patti mapping (Two-digit keys with 10 values each)
  static const Map<String, List<String>> cyclePatti = {
    '00': [
      '100',
      '200',
      '300',
      '400',
      '500',
      '600',
      '700',
      '800',
      '900',
      '000',
    ],
    '10': [
      '110',
      '120',
      '130',
      '140',
      '150',
      '160',
      '170',
      '180',
      '190',
      '100',
    ],
    '11': [
      '111',
      '112',
      '113',
      '114',
      '115',
      '116',
      '117',
      '118',
      '119',
      '110',
    ],
    '12': [
      '112',
      '122',
      '123',
      '124',
      '125',
      '126',
      '127',
      '128',
      '129',
      '120',
    ],
    '13': [
      '113',
      '123',
      '133',
      '134',
      '135',
      '136',
      '137',
      '138',
      '139',
      '130',
    ],
    '14': [
      '114',
      '124',
      '134',
      '144',
      '145',
      '146',
      '147',
      '148',
      '149',
      '140',
    ],
    '15': [
      '115',
      '125',
      '135',
      '145',
      '155',
      '156',
      '157',
      '158',
      '159',
      '150',
    ],
    '16': [
      '116',
      '126',
      '136',
      '146',
      '156',
      '166',
      '167',
      '168',
      '169',
      '160',
    ],
    '17': [
      '117',
      '127',
      '137',
      '147',
      '157',
      '167',
      '177',
      '178',
      '179',
      '170',
    ],
    '18': [
      '118',
      '128',
      '138',
      '148',
      '158',
      '168',
      '178',
      '188',
      '189',
      '180',
    ],
    '19': [
      '119',
      '129',
      '139',
      '149',
      '159',
      '169',
      '179',
      '189',
      '199',
      '190',
    ],
    '20': [
      '120',
      '220',
      '230',
      '240',
      '250',
      '260',
      '270',
      '280',
      '290',
      '200',
    ],
    '22': [
      '122',
      '222',
      '223',
      '224',
      '225',
      '226',
      '227',
      '228',
      '229',
      '220',
    ],
    '23': [
      '123',
      '223',
      '233',
      '234',
      '235',
      '236',
      '237',
      '238',
      '239',
      '230',
    ],
    '24': [
      '124',
      '224',
      '234',
      '244',
      '245',
      '246',
      '247',
      '248',
      '249',
      '240',
    ],
    '25': [
      '125',
      '225',
      '235',
      '245',
      '255',
      '256',
      '257',
      '258',
      '259',
      '250',
    ],
    '26': [
      '126',
      '226',
      '236',
      '246',
      '256',
      '266',
      '267',
      '268',
      '269',
      '260',
    ],
    '27': [
      '127',
      '227',
      '237',
      '247',
      '257',
      '267',
      '277',
      '278',
      '279',
      '270',
    ],
    '28': [
      '128',
      '228',
      '238',
      '248',
      '258',
      '268',
      '278',
      '288',
      '289',
      '280',
    ],
    '29': [
      '129',
      '229',
      '239',
      '249',
      '259',
      '269',
      '279',
      '289',
      '299',
      '290',
    ],
    '30': [
      '130',
      '230',
      '330',
      '340',
      '350',
      '360',
      '370',
      '380',
      '390',
      '300',
    ],
    '33': [
      '133',
      '233',
      '333',
      '334',
      '335',
      '336',
      '337',
      '338',
      '339',
      '330',
    ],
    '34': [
      '134',
      '234',
      '334',
      '344',
      '345',
      '346',
      '347',
      '348',
      '349',
      '340',
    ],
    '35': [
      '135',
      '235',
      '335',
      '345',
      '355',
      '356',
      '357',
      '358',
      '359',
      '350',
    ],
    '36': [
      '136',
      '236',
      '336',
      '346',
      '356',
      '366',
      '367',
      '368',
      '369',
      '360',
    ],
    '37': [
      '137',
      '237',
      '337',
      '347',
      '357',
      '367',
      '377',
      '378',
      '379',
      '370',
    ],
    '38': [
      '138',
      '238',
      '338',
      '348',
      '358',
      '368',
      '378',
      '388',
      '389',
      '380',
    ],
    '39': [
      '139',
      '239',
      '339',
      '349',
      '359',
      '369',
      '379',
      '389',
      '399',
      '390',
    ],
    '40': [
      '140',
      '240',
      '340',
      '440',
      '450',
      '460',
      '470',
      '480',
      '490',
      '400',
    ],
    '44': [
      '144',
      '244',
      '344',
      '444',
      '445',
      '446',
      '447',
      '448',
      '449',
      '440',
    ],
    '45': [
      '145',
      '245',
      '345',
      '445',
      '455',
      '456',
      '457',
      '458',
      '459',
      '450',
    ],
    '46': [
      '146',
      '246',
      '346',
      '446',
      '456',
      '466',
      '467',
      '468',
      '469',
      '460',
    ],
    '47': [
      '147',
      '247',
      '347',
      '447',
      '457',
      '467',
      '477',
      '478',
      '479',
      '470',
    ],
    '48': [
      '148',
      '248',
      '348',
      '448',
      '458',
      '468',
      '478',
      '488',
      '489',
      '480',
    ],
    '49': [
      '149',
      '249',
      '349',
      '449',
      '459',
      '469',
      '479',
      '489',
      '499',
      '490',
    ],
    '50': [
      '150',
      '250',
      '350',
      '450',
      '550',
      '560',
      '570',
      '580',
      '590',
      '500',
    ],
    '55': [
      '155',
      '255',
      '355',
      '455',
      '555',
      '556',
      '557',
      '558',
      '559',
      '550',
    ],
    '56': [
      '156',
      '256',
      '356',
      '456',
      '556',
      '566',
      '567',
      '568',
      '569',
      '560',
    ],
    '57': [
      '157',
      '257',
      '357',
      '457',
      '557',
      '567',
      '577',
      '578',
      '579',
      '570',
    ],
    '58': [
      '158',
      '258',
      '358',
      '458',
      '558',
      '568',
      '578',
      '588',
      '589',
      '580',
    ],
    '59': [
      '159',
      '259',
      '359',
      '459',
      '559',
      '569',
      '579',
      '589',
      '599',
      '590',
    ],
    '60': [
      '160',
      '260',
      '360',
      '460',
      '560',
      '660',
      '670',
      '680',
      '690',
      '600',
    ],
    '66': [
      '166',
      '266',
      '366',
      '466',
      '566',
      '666',
      '667',
      '668',
      '669',
      '660',
    ],
    '67': [
      '167',
      '267',
      '367',
      '467',
      '567',
      '667',
      '677',
      '678',
      '679',
      '670',
    ],
    '68': [
      '168',
      '268',
      '368',
      '468',
      '568',
      '668',
      '678',
      '688',
      '689',
      '680',
    ],
    '69': [
      '169',
      '269',
      '369',
      '469',
      '569',
      '669',
      '679',
      '689',
      '699',
      '690',
    ],
    '70': [
      '170',
      '270',
      '370',
      '470',
      '570',
      '670',
      '770',
      '780',
      '790',
      '700',
    ],
    '77': [
      '177',
      '277',
      '377',
      '477',
      '577',
      '677',
      '777',
      '778',
      '779',
      '770',
    ],
    '78': [
      '178',
      '278',
      '378',
      '478',
      '578',
      '678',
      '778',
      '788',
      '789',
      '780',
    ],
    '79': [
      '179',
      '279',
      '379',
      '479',
      '579',
      '679',
      '779',
      '789',
      '799',
      '790',
    ],
    '80': [
      '180',
      '280',
      '380',
      '480',
      '580',
      '680',
      '780',
      '880',
      '890',
      '800',
    ],
    '88': [
      '188',
      '288',
      '388',
      '488',
      '588',
      '688',
      '788',
      '888',
      '889',
      '880',
    ],
    '89': [
      '189',
      '289',
      '389',
      '489',
      '589',
      '689',
      '789',
      '889',
      '899',
      '890',
    ],
    '90': [
      '190',
      '290',
      '390',
      '490',
      '590',
      '690',
      '790',
      '890',
      '990',
      '900',
    ],
    '99': [
      '199',
      '299',
      '399',
      '499',
      '599',
      '699',
      '799',
      '899',
      '999',
      '990',
    ],
  };

  // Helper Methods for digitPanaMap
  /// Get all pana values for a given digit
  static List<String>? getPanasForDigit(String digit) {
    return digitPanaMap[digit];
  }

  /// Check if a pana belongs to a specific digit
  static bool isPanaInDigit(String pana, String digit) {
    final panas = digitPanaMap[digit];
    return panas?.contains(pana) ?? false;
  }

  /// Get all digit keys
  static List<String> getAllDigits() {
    return digitPanaMap.keys.toList();
  }

  /// Find which digit contains a given pana
  static String? findDigitForPana(String pana) {
    for (var entry in digitPanaMap.entries) {
      if (entry.value.contains(pana)) {
        return entry.key;
      }
    }
    return null;
  }

  /// Get count of panas in a digit group
  static int getDigitPanaCount(String digit) {
    return digitPanaMap[digit]?.length ?? 0;
  }

  // Helper Methods for panaCombinations
  /// Get all pana combinations for a given digit
  static List<String>? getPanaCombinationsForDigit(String digit) {
    return panaCombinations[digit];
  }

  /// Check if a pana belongs to a specific pana combination
  static bool isPanaInCombination(String pana, String digit) {
    final panas = panaCombinations[digit];
    return panas?.contains(pana) ?? false;
  }

  /// Find which digit combination contains a given pana
  static String? findCombinationDigitForPana(String pana) {
    for (var entry in panaCombinations.entries) {
      if (entry.value.contains(pana)) {
        return entry.key;
      }
    }
    return null;
  }

  // Helper Methods for triplePanaCombinations
  /// Get all triple pana combinations
  static List<String> getAllTriplePana() {
    return triplePanaCombinations;
  }

  /// Check if a pana is a triple pana
  static bool isTriplePana(String pana) {
    return triplePanaCombinations.contains(pana);
  }

  // Helper Methods for familyPana
  /// Get all child pana values for a given family pana
  static List<String>? getChildPanasForFamily(String familyPanaKey) {
    return familyPana[familyPanaKey];
  }

  /// Check if a pana belongs to a specific family pana
  static bool isPanaInFamily(String pana, String familyPanaKey) {
    final panas = familyPana[familyPanaKey];
    return panas?.contains(pana) ?? false;
  }

  /// Get all family pana keys
  static List<String> getAllFamilyPanaKeys() {
    return familyPana.keys.toList();
  }

  /// Find which family pana contains a given pana
  static String? findFamilyForPana(String pana) {
    for (var entry in familyPana.entries) {
      if (entry.value.contains(pana)) {
        return entry.key;
      }
    }
    return null;
  }

  /// Get count of panas in a family pana group
  static int getFamilyPanaCount(String familyPanaKey) {
    return familyPana[familyPanaKey]?.length ?? 0;
  }

  // Helper Methods for cyclePatti
  /// Get all pana values for a given cycle patti
  static List<String>? getPanasForCyclePatti(String cyclePattiKey) {
    return cyclePatti[cyclePattiKey];
  }

  /// Check if a pana belongs to a specific cycle patti
  static bool isPanaInCyclePatti(String pana, String cyclePattiKey) {
    final panas = cyclePatti[cyclePattiKey];
    return panas?.contains(pana) ?? false;
  }

  /// Get all cycle patti keys
  static List<String> getAllCyclePattiKeys() {
    return cyclePatti.keys.toList();
  }

  /// Find which cycle patti contains a given pana
  static String? findCyclePattiForPana(String pana) {
    for (var entry in cyclePatti.entries) {
      if (entry.value.contains(pana)) {
        return entry.key;
      }
    }
    return null;
  }

  // Helper Methods for singlePana
  /// Get all pana values for a given single digit

  // General Helper Methods
  /// Get all available game types
  static Map<String, dynamic> getAllGameData() {
    return {
      'digitPanaMap': digitPanaMap,
      'panaCombinations': panaCombinations,
      'triplePanaCombinations': triplePanaCombinations,
      'familyPana': familyPana,
      'cyclePatti': cyclePatti,
    };
  }

  /// Validate if a pana exists in any game type
  static bool isValidPana(String pana) {
    // Check in digitPanaMap
    for (var list in digitPanaMap.values) {
      if (list.contains(pana)) return true;
    }
    // Check in panaCombinations
    for (var list in panaCombinations.values) {
      if (list.contains(pana)) return true;
    }
    // Check in triplePanaCombinations
    if (triplePanaCombinations.contains(pana)) return true;
    // Check in familyPana
    for (var list in familyPana.values) {
      if (list.contains(pana)) return true;
    }
    // Check in cyclePatti
    for (var list in cyclePatti.values) {
      if (list.contains(pana)) return true;
    }
    // Check in singlePana

    return false;
  }

  /// Get all unique pana values across all game types
  static Set<String> getAllUniquePanas() {
    final Set<String> allPanas = {};

    for (var list in digitPanaMap.values) {
      allPanas.addAll(list);
    }
    for (var list in panaCombinations.values) {
      allPanas.addAll(list);
    }
    allPanas.addAll(triplePanaCombinations);
    for (var list in familyPana.values) {
      allPanas.addAll(list);
    }
    for (var list in cyclePatti.values) {
      allPanas.addAll(list);
    }

    return allPanas;
  }

  /// Get game type for a given pana
  static String? getGameTypeForPana(String pana) {
    for (var list in digitPanaMap.values) {
      if (list.contains(pana)) return 'Digit Pana';
    }
    for (var list in panaCombinations.values) {
      if (list.contains(pana)) return 'Pana Combination';
    }
    if (triplePanaCombinations.contains(pana)) return 'Triple Pana';
    for (var list in familyPana.values) {
      if (list.contains(pana)) return 'Family Pana';
    }
    for (var list in cyclePatti.values) {
      if (list.contains(pana)) return 'Cycle Patti';
    }

    return null;
  }
}

extension GameDataExtension on BuildContext {
  GameData get gameData => GameData();
}
