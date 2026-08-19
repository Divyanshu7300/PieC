import 'dart:convert';
import 'package:flutter/material.dart';

enum HairStyle {
  cyberPunkFade,
  animeSpiky,
  pompadourVolume,
  curlyAfro,
  longFlowyWavy,
  streetwearDreads,
  undercutSlick,
  kpopCurtains,
  cyberBraids,
  buzzCutFade,
}

enum EyeShape {
  almondAnime,
  roundExpressive,
  sharpCyber,
  coolRelaxed,
}

enum IrisColor {
  cyberCyan,
  electricPurple,
  neonEmerald,
  amberGold,
  oceanBlue,
  deepHazel,
  rubyRed,
}

enum FacialHair {
  none,
  stubbleShadow,
  cyberGoatee,
  fullBeard,
  mustacheClassic,
}

enum OutfitStyle {
  cyberHoodieWithGlow,
  bomberJacketLeather,
  streetwearGraphicTee,
  neonTechArmor,
  cozyOversizedSweater,
  futuristicSuit,
}

enum AvatarAccessory {
  none,
  studioHeadphonesLed,
  cyberVisorHolo,
  retroAviatorGlasses,
  matrixDarkShades,
  goldCyberChain,
  angelNeonHalo,
  devilHornsGlow,
  royalCyberCrown,
  streetwearBeanie,
}

enum AvatarAuraEffect {
  none,
  cyberSparks,
  neonHearts,
  matrixCodeGlow,
  fireFlameEnergy,
  galaxyNebula,
}

enum AvatarPose {
  chillStand,
  peaceSign,
  wavingHand,
  armsCrossed,
  hypedParty,
}

class AvatarConfig {
  final int skinColorHex;
  final int skinShadowHex;
  final HairStyle hairStyle;
  final int hairBaseColorHex;
  final int hairHighlightColorHex;
  final EyeShape eyeShape;
  final IrisColor irisColor;
  final FacialHair facialHair;
  final OutfitStyle outfitStyle;
  final int outfitPrimaryColorHex;
  final int outfitSecondaryColorHex;
  final AvatarAccessory accessory;
  final AvatarAuraEffect auraEffect;
  final AvatarPose pose;
  final int glowColorHex;
  final double faceTiltX; // 3D Tilt for parallax
  final double faceTiltY;

  const AvatarConfig({
    this.skinColorHex = 0xFFFFD7B2,
    this.skinShadowHex = 0xFFE0A77A,
    this.hairStyle = HairStyle.cyberPunkFade,
    this.hairBaseColorHex = 0xFF1C1427,
    this.hairHighlightColorHex = 0xFF00F0FF,
    this.eyeShape = EyeShape.almondAnime,
    this.irisColor = IrisColor.cyberCyan,
    this.facialHair = FacialHair.none,
    this.outfitStyle = OutfitStyle.cyberHoodieWithGlow,
    this.outfitPrimaryColorHex = 0xFF6366F1,
    this.outfitSecondaryColorHex = 0xFF00F0FF,
    this.accessory = AvatarAccessory.studioHeadphonesLed,
    this.auraEffect = AvatarAuraEffect.none,
    this.pose = AvatarPose.chillStand,
    this.glowColorHex = 0xFF00F0FF,
    this.faceTiltX = 0.0,
    this.faceTiltY = 0.0,
  });

  Color get skinColor => Color(skinColorHex);
  Color get skinShadowColor => Color(skinShadowHex);
  Color get hairBaseColor => Color(hairBaseColorHex);
  Color get hairHighlightColor => Color(hairHighlightColorHex);
  Color get outfitPrimaryColor => Color(outfitPrimaryColorHex);
  Color get outfitSecondaryColor => Color(outfitSecondaryColorHex);
  Color get glowColor => Color(glowColorHex);

  Color get irisColorValue {
    switch (irisColor) {
      case IrisColor.cyberCyan:
        return const Color(0xFF00F0FF);
      case IrisColor.electricPurple:
        return const Color(0xFFB026FF);
      case IrisColor.neonEmerald:
        return const Color(0xFF00FF9D);
      case IrisColor.amberGold:
        return const Color(0xFFFFD600);
      case IrisColor.oceanBlue:
        return const Color(0xFF2563EB);
      case IrisColor.rubyRed:
        return const Color(0xFFFF2A85);
      case IrisColor.deepHazel:
      default:
        return const Color(0xFF78350F);
    }
  }

  AvatarConfig copyWith({
    int? skinColorHex,
    int? skinShadowHex,
    HairStyle? hairStyle,
    int? hairBaseColorHex,
    int? hairHighlightColorHex,
    EyeShape? eyeShape,
    IrisColor? irisColor,
    FacialHair? facialHair,
    OutfitStyle? outfitStyle,
    int? outfitPrimaryColorHex,
    int? outfitSecondaryColorHex,
    AvatarAccessory? accessory,
    AvatarAuraEffect? auraEffect,
    AvatarPose? pose,
    int? glowColorHex,
    double? faceTiltX,
    double? faceTiltY,
  }) {
    return AvatarConfig(
      skinColorHex: skinColorHex ?? this.skinColorHex,
      skinShadowHex: skinShadowHex ?? this.skinShadowHex,
      hairStyle: hairStyle ?? this.hairStyle,
      hairBaseColorHex: hairBaseColorHex ?? this.hairBaseColorHex,
      hairHighlightColorHex: hairHighlightColorHex ?? this.hairHighlightColorHex,
      eyeShape: eyeShape ?? this.eyeShape,
      irisColor: irisColor ?? this.irisColor,
      facialHair: facialHair ?? this.facialHair,
      outfitStyle: outfitStyle ?? this.outfitStyle,
      outfitPrimaryColorHex: outfitPrimaryColorHex ?? this.outfitPrimaryColorHex,
      outfitSecondaryColorHex:
          outfitSecondaryColorHex ?? this.outfitSecondaryColorHex,
      accessory: accessory ?? this.accessory,
      auraEffect: auraEffect ?? this.auraEffect,
      pose: pose ?? this.pose,
      glowColorHex: glowColorHex ?? this.glowColorHex,
      faceTiltX: faceTiltX ?? this.faceTiltX,
      faceTiltY: faceTiltY ?? this.faceTiltY,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'skinColorHex': skinColorHex,
      'skinShadowHex': skinShadowHex,
      'hairStyle': hairStyle.name,
      'hairBaseColorHex': hairBaseColorHex,
      'hairHighlightColorHex': hairHighlightColorHex,
      'eyeShape': eyeShape.name,
      'irisColor': irisColor.name,
      'facialHair': facialHair.name,
      'outfitStyle': outfitStyle.name,
      'outfitPrimaryColorHex': outfitPrimaryColorHex,
      'outfitSecondaryColorHex': outfitSecondaryColorHex,
      'accessory': accessory.name,
      'auraEffect': auraEffect.name,
      'pose': pose.name,
      'glowColorHex': glowColorHex,
      'faceTiltX': faceTiltX,
      'faceTiltY': faceTiltY,
    };
  }

  factory AvatarConfig.fromMap(Map<String, dynamic> map) {
    return AvatarConfig(
      skinColorHex: map['skinColorHex'] ?? 0xFFFFD7B2,
      skinShadowHex: map['skinShadowHex'] ?? 0xFFE0A77A,
      hairStyle: HairStyle.values.firstWhere(
        (e) => e.name == map['hairStyle'],
        orElse: () => HairStyle.cyberPunkFade,
      ),
      hairBaseColorHex: map['hairBaseColorHex'] ?? 0xFF1C1427,
      hairHighlightColorHex: map['hairHighlightColorHex'] ?? 0xFF00F0FF,
      eyeShape: EyeShape.values.firstWhere(
        (e) => e.name == map['eyeShape'],
        orElse: () => EyeShape.almondAnime,
      ),
      irisColor: IrisColor.values.firstWhere(
        (e) => e.name == map['irisColor'],
        orElse: () => IrisColor.cyberCyan,
      ),
      facialHair: FacialHair.values.firstWhere(
        (e) => e.name == map['facialHair'],
        orElse: () => FacialHair.none,
      ),
      outfitStyle: OutfitStyle.values.firstWhere(
        (e) => e.name == map['outfitStyle'],
        orElse: () => OutfitStyle.cyberHoodieWithGlow,
      ),
      outfitPrimaryColorHex: map['outfitPrimaryColorHex'] ?? 0xFF6366F1,
      outfitSecondaryColorHex: map['outfitSecondaryColorHex'] ?? 0xFF00F0FF,
      accessory: AvatarAccessory.values.firstWhere(
        (e) => e.name == map['accessory'],
        orElse: () => AvatarAccessory.studioHeadphonesLed,
      ),
      auraEffect: AvatarAuraEffect.values.firstWhere(
        (e) => e.name == map['auraEffect'],
        orElse: () => AvatarAuraEffect.cyberSparks,
      ),
      pose: AvatarPose.values.firstWhere(
        (e) => e.name == map['pose'],
        orElse: () => AvatarPose.chillStand,
      ),
      glowColorHex: map['glowColorHex'] ?? 0xFF00F0FF,
      faceTiltX: (map['faceTiltX'] as num?)?.toDouble() ?? 0.0,
      faceTiltY: (map['faceTiltY'] as num?)?.toDouble() ?? 0.0,
    );
  }

  String toJson() => json.encode(toMap());

  factory AvatarConfig.fromJson(String source) =>
      AvatarConfig.fromMap(json.decode(source));
}
