class CampaignWorldDefinition {
  final String id;
  final String name;
  final String description;
  final int levelStart;
  final int levelEnd;
  final String background;
  final String theme;

  const CampaignWorldDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.levelStart,
    required this.levelEnd,
    this.background = '',
    this.theme = '',
  });

  bool containsLevel(int levelId) => levelId >= levelStart && levelId <= levelEnd;

  static List<CampaignWorldDefinition> defaultWorlds() {
    return const [
      CampaignWorldDefinition(
        id: 'color_garden',
        name: 'Color Garden',
        description: 'A vibrant garden blooming with color',
        levelStart: 1,
        levelEnd: 30,
        theme: 'garden',
      ),
      CampaignWorldDefinition(
        id: 'color_valley',
        name: 'Color Valley',
        description: 'A deep valley of shifting hues',
        levelStart: 31,
        levelEnd: 65,
        theme: 'valley',
      ),
      CampaignWorldDefinition(
        id: 'color_factory',
        name: 'Color Factory',
        description: 'A dazzling factory of pure color',
        levelStart: 66,
        levelEnd: 100,
        theme: 'factory',
      ),
    ];
  }
}
