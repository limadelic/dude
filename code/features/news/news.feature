Feature: News

  Scenario: happy path

    # Paperboy
    * ~ claude --version
      | 2.1.90 |
    * ~ gh release list limit 1
      | v2.1.96 |
    * ~ gh release list
      | v2.1.96 |
      | v2.1.95 |
      | v2.1.94 |
      | v2.1.93 |
      | v2.1.92 |
    * ~ gh release view v2.1.96
      | Fix critical bug |
    * ~ gh release view v2.1.95
      | New feature |
    * ~ gh release view v2.1.94
      | Minor update |
    * ~ gh release view v2.1.93
      | Patch release |
    * ~ gh release view v2.1.92
      | Maintenance |

    * > /news:
      | Installed: 2.1.90, Latest: v2.1.96 |
      | v2.1.96                            |
      | Fix critical bug                   |
      | v2.1.95                            |
      | New feature                        |
      | v2.1.94                            |
      | Minor update                       |
      | v2.1.93                            |
      | Patch release                      |
      | v2.1.92                            |
      | Maintenance                        |

  Scenario: custom limit

    * ~ claude --version
      | 2.1.90 |
    * ~ gh release list limit 1
      | v2.1.96 |
    * ~ gh release list limit 3
      | v2.1.96 |
      | v2.1.95 |
      | v2.1.94 |
    * ~ gh release view v2.1.96
      | Fix critical bug |
    * ~ gh release view v2.1.95
      | New feature |
    * ~ gh release view v2.1.94
      | Minor update |

    * > /news --limit 3:
      | Installed: 2.1.90, Latest: v2.1.96 |
      | v2.1.96                            |
      | Fix critical bug                   |
      | v2.1.95                            |
      | New feature                        |
      | v2.1.94                            |
      | Minor update                       |
