import 'models.dart';

/// Stable goal ids – referenced by tests, the widget and notifications.
abstract final class GoalIds {
  static const water = 'water';
  static const steps = 'steps';
  static const noSugaryDrinks = 'no_sugary_drinks';
  static const veggies = 'veggies';
  static const meals = 'meals';
  static const noMorningSugar = 'no_morning_sugar';
  static const sweets = 'sweets';
  static const socialMedia = 'social_media';
  static const reading = 'reading';
  static const workouts = 'workouts';
  static const junkFood = 'junk_food';
}

/// The goal list the couple agreed on. Used for every new challenge round
/// (and then editable per round).
const List<GoalDef> defaultGoals = [
  GoalDef(
    id: GoalIds.water,
    titleHe: '8 כוסות מים',
    titleEn: '8 glasses of water',
    type: GoalType.counter,
    comparison: Comparison.atLeast,
    target: 8,
    period: GoalPeriod.daily,
    icon: '💧',
  ),
  GoalDef(
    id: GoalIds.steps,
    titleHe: '10,000 צעדים',
    titleEn: '10,000 steps',
    type: GoalType.number,
    comparison: Comparison.atLeast,
    target: 10000,
    period: GoalPeriod.daily,
    icon: '👟',
    step: 1000,
  ),
  GoalDef(
    id: GoalIds.noSugaryDrinks,
    titleHe: 'בלי שתייה מתוקה',
    titleEn: 'No sugary drinks',
    type: GoalType.boolean,
    comparison: Comparison.atLeast,
    target: 1,
    period: GoalPeriod.daily,
    icon: '🥤',
  ),
  GoalDef(
    id: GoalIds.veggies,
    titleHe: 'ירקות בכל ארוחה',
    titleEn: 'Vegetables with every meal',
    type: GoalType.boolean,
    comparison: Comparison.atLeast,
    target: 1,
    period: GoalPeriod.daily,
    icon: '🥗',
  ),
  GoalDef(
    id: GoalIds.meals,
    titleHe: '3 ארוחות',
    titleEn: '3 meals',
    type: GoalType.counter,
    comparison: Comparison.exactly,
    target: 3,
    period: GoalPeriod.daily,
    icon: '🍽️',
  ),
  GoalDef(
    id: GoalIds.noMorningSugar,
    titleHe: 'בלי סוכר בבוקר',
    titleEn: 'No sugar in the morning',
    type: GoalType.boolean,
    comparison: Comparison.atLeast,
    target: 1,
    period: GoalPeriod.daily,
    icon: '🌅',
  ),
  GoalDef(
    id: GoalIds.sweets,
    titleHe: 'מקסימום ממתק/חטיף אחד',
    titleEn: 'Max one sweet/snack',
    type: GoalType.counter,
    comparison: Comparison.atMost,
    target: 1,
    period: GoalPeriod.daily,
    icon: '🍫',
  ),
  GoalDef(
    id: GoalIds.socialMedia,
    titleHe: 'רשתות חברתיות עד שעה',
    titleEn: 'Social media max 1 hour',
    type: GoalType.minutes,
    comparison: Comparison.atMost,
    target: 60,
    period: GoalPeriod.daily,
    icon: '📱',
    step: 15,
  ),
  GoalDef(
    id: GoalIds.reading,
    titleHe: 'מינימום שעה קריאה',
    titleEn: 'At least 1 hour reading',
    type: GoalType.minutes,
    comparison: Comparison.atLeast,
    target: 60,
    period: GoalPeriod.daily,
    icon: '📖',
    step: 15,
  ),
  GoalDef(
    id: GoalIds.workouts,
    titleHe: '3 אימונים בשבוע',
    titleEn: '3 workouts a week',
    type: GoalType.workouts,
    comparison: Comparison.atLeast,
    target: 3,
    period: GoalPeriod.weekly,
    icon: '🏋️',
    requirements: {'run': 1, 'strength': 2, 'minMinutes': 30},
  ),
  GoalDef(
    id: GoalIds.junkFood,
    titleHe: 'ג׳אנק פוד עד פעם בשבוע',
    titleEn: 'Junk food max once a week',
    type: GoalType.counter,
    comparison: Comparison.atMost,
    target: 1,
    period: GoalPeriod.weekly,
    icon: '🍔',
  ),
];
