export interface Parashah {
  id: number;
  name: string;
  hebrew: string;
  theme: string;
  torah: string;
  haftarah: string;
}

export const parashot: Parashah[] = [
  { 
    id: 1, 
    name: "Bereshit", 
    hebrew: "בְּרֵאשִׁית",
    theme: "La Création",
    torah: "Genèse 1:1 - 6:8",
    haftarah: "Isaïe 42:5-43:10"
  },
  { 
    id: 2, 
    name: "Noach", 
    hebrew: "נֹחַ",
    theme: "Le Déluge et Babel",
    torah: "Genèse 6:9 - 11:32",
    haftarah: "Isaïe 54:1-55:5"
  },
  { 
    id: 3, 
    name: "Lech-Lecha", 
    hebrew: "לֶךְ־לְךָ",
    theme: "L'appel d'Abraham",
    torah: "Genèse 12:1 - 17:27",
    haftarah: "Isaïe 40:27-41:16"
  },
  { 
    id: 4, 
    name: "Vayera", 
    hebrew: "וַיֵּרָא",
    theme: "La visite des anges",
    torah: "Genèse 18:1 - 22:24",
    haftarah: "II Rois 4:1-37"
  },
  { 
    id: 5, 
    name: "Chayei Sarah", 
    hebrew: "חַיֵּי שָׂרָה",
    theme: "La mort de Sarah",
    torah: "Genèse 23:1 - 25:18",
    haftarah: "I Rois 1:1-31"
  },
  { 
    id: 6, 
    name: "Toldot", 
    hebrew: "תּוֹלְדֹת",
    theme: "Isaac et ses fils",
    torah: "Genèse 25:19 - 28:9",
    haftarah: "Malachie 1:1-2:7"
  },
  { 
    id: 7, 
    name: "Vayetze", 
    hebrew: "וַיֵּצֵא",
    theme: "L'échelle de Jacob",
    torah: "Genèse 28:10 - 32:3",
    haftarah: "Hosée 11:7-12:12"
  },
  { 
    id: 8, 
    name: "Vayishlach", 
    hebrew: "וַיִּשְׁלַח",
    theme: "Jacob devient Israël",
    torah: "Genèse 32:4 - 36:43",
    haftarah: "Osee 11:7-12:12"
  },
  { 
    id: 9, 
    name: "Vayeshev", 
    hebrew: "וַיֵּשֶׁב",
    theme: "Joseph et ses frères",
    torah: "Genèse 37:1 - 40:23",
    haftarah: "Amos 2:6-3:8"
  },
  { 
    id: 10, 
    name: "Miketz", 
    hebrew: "מִקֵּץ",
    theme: "Les rêves de Pharaon",
    torah: "Genèse 41:1 - 44:17",
    haftarah: "I Rois 3:5-4:1"
  },
  { 
    id: 11, 
    name: "Vayigash", 
    hebrew: "וַיִּגַּשׁ",
    theme: "Juda s'approche",
    torah: "Genèse 44:18 - 47:27",
    haftarah: "Ézéchiel 37:15-28"
  },
  { 
    id: 12, 
    name: "Vayechi", 
    hebrew: "וַיְחִי",
    theme: "Jacob bénit ses fils",
    torah: "Genèse 47:28 - 50:26",
    haftarah: "I Rois 2:1-12"
  },
  { 
    id: 13, 
    name: "Shemot", 
    hebrew: "שְׁמוֹת",
    theme: "L'oppression en Égypte",
    torah: "Exode 1:1 - 6:1",
    haftarah: "Isaïe 27:6-28:13, 29:22-23"
  },
  { 
    id: 14, 
    name: "Vaera", 
    hebrew: "וָאֵרָא",
    theme: "Les plaies d'Égypte",
    torah: "Exode 6:2 - 9:35",
    haftarah: "Ézéchiel 28:25-29:21"
  },
  { 
    id: 15, 
    name: "Bo", 
    hebrew: "בֹּא",
    theme: "Les dernières plaies",
    torah: "Exode 10:1 - 13:16",
    haftarah: "Jérémie 46:13-28"
  },
  { 
    id: 16, 
    name: "Beshalach", 
    hebrew: "בְּשַׁלַּח",
    theme: "La sortie d'Égypte",
    torah: "Exode 13:17 - 17:16",
    haftarah: "Juges 4:4-5:31"
  },
  { 
    id: 17, 
    name: "Yitro", 
    hebrew: "יִתְרוֹ",
    theme: "Les Dix Commandements",
    torah: "Exode 18:1 - 20:23",
    haftarah: "Isaïe 6:1-7:6, 9:5-6"
  },
  { 
    id: 18, 
    name: "Mishpatim", 
    hebrew: "מִשְׁפָּטִים",
    theme: "Les lois civiles",
    torah: "Exode 21:1 - 24:18",
    haftarah: "II Rois 11:17-12:17"
  },
  { 
    id: 19, 
    name: "Terumah", 
    hebrew: "תְּרוּמָה",
    theme: "Construction du Tabernacle",
    torah: "Exode 25:1 - 27:19",
    haftarah: "I Rois 5:26-6:13"
  },
  { 
    id: 20, 
    name: "Tetzaveh", 
    hebrew: "תְּצַוֶּה",
    theme: "Les vêtements sacerdotaux",
    torah: "Exode 27:20 - 30:10",
    haftarah: "I Rois 7:51-8:21"
  },
  { 
    id: 21, 
    name: "Ki Tisa", 
    hebrew: "כִּי תִשָּׂא",
    theme: "Le veau d'or",
    torah: "Exode 30:11 - 34:35",
    haftarah: "I Rois 18:1-39"
  },
  { 
    id: 22, 
    name: "Vayakhel", 
    hebrew: "וַיַּקְהֵל",
    theme: "Construction du Tabernacle",
    torah: "Exode 35:1 - 38:20",
    haftarah: "I Rois 7:51-8:21"
  },
  { 
    id: 23, 
    name: "Pekudei", 
    hebrew: "פְקוּדֵי",
    theme: "Achèvement du Tabernacle",
    torah: "Exode 38:21 - 40:38",
    haftarah: "I Rois 7:51-8:21"
  },
  { 
    id: 24, 
    name: "Vayikra", 
    hebrew: "וַיִּקְרָא",
    theme: "Les sacrifices",
    torah: "Lévitique 1:1 - 5:26",
    haftarah: "II Samuel 24:1-25"
  },
  { 
    id: 25, 
    name: "Tzav", 
    hebrew: "צַו",
    theme: "Les lois sacrificielles",
    torah: "Lévitique 6:1 - 8:36",
    haftarah: "I Samuel 15:2-34"
  },
  { 
    id: 26, 
    name: "Shemini", 
    hebrew: "שְׁמִינִי",
    theme: "Consécration des prêtres",
    torah: "Lévitique 9:1 - 11:47",
    haftarah: "II Samuel 6:1-7:17"
  },
  { 
    id: 27, 
    name: "Tazria", 
    hebrew: "תַזְרִיעַ",
    theme: "Pureté rituelle",
    torah: "Lévitique 12:1 - 13:59",
    haftarah: "II Rois 4:42-5:19"
  },
  { 
    id: 28, 
    name: "Metzora", 
    hebrew: "מְצֹרָע",
    theme: "Purification du lépreux",
    torah: "Lévitique 14:1 - 15:33",
    haftarah: "II Rois 7:3-20"
  },
  { 
    id: 29, 
    name: "Acharei Mot", 
    hebrew: "אַחֲרֵי מוֹת",
    theme: "Yom Kippour",
    torah: "Lévitique 16:1 - 18:30",
    haftarah: "Amos 9:7-15"
  },
  { 
    id: 30, 
    name: "Kedoshim", 
    hebrew: "קְדֹשִׁים",
    theme: "Soyez saints",
    torah: "Lévitique 19:1 - 20:27",
    haftarah: "Amos 9:7-15"
  },
  { 
    id: 31, 
    name: "Emor", 
    hebrew: "אֱמֹר",
    theme: "Les fêtes sacrées",
    torah: "Lévitique 21:1 - 24:23",
    haftarah: "I Samuel 20:18-42"
  },
  { 
    id: 32, 
    name: "Behar", 
    hebrew: "בְּהַר",
    theme: "L'année jubilaire",
    torah: "Lévitique 25:1 - 26:2",
    haftarah: "I Samuel 20:18-42"
  },
  { 
    id: 33, 
    name: "Bechukotai", 
    hebrew: "בְּחֻקֹּתַי",
    theme: "Bénédictions et malédictions",
    torah: "Lévitique 26:3 - 27:34",
    haftarah: "I Samuel 20:18-42"
  },
  { 
    id: 34, 
    name: "Bamidbar", 
    hebrew: "בְּמִדְבַּר",
    theme: "Recensement dans le désert",
    torah: "Nombres 1:1 - 4:20",
    haftarah: "Hosée 2:1-22"
  },
  { 
    id: 35, 
    name: "Nasso", 
    hebrew: "נָשׂא",
    theme: "Les offrandes des princes",
    torah: "Nombres 4:21 - 7:89",
    haftarah: "Juges 13:2-25"
  },
  { 
    id: 36, 
    name: "Beha'alotcha", 
    hebrew: "בְּהַעֲלֹתְךָ",
    theme: "L'allumage de la Menorah",
    torah: "Nombres 8:1 - 12:16",
    haftarah: "Zacharie 2:14-4:7"
  },
  { 
    id: 37, 
    name: "Shlach", 
    hebrew: "שְׁלַח",
    theme: "Les explorateurs",
    torah: "Nombres 13:1 - 15:41",
    haftarah: "I Samuel 26:1-25"
  },
  { 
    id: 38, 
    name: "Korach", 
    hebrew: "קֹרַח",
    theme: "La rébellion de Korach",
    torah: "Nombres 16:1 - 18:32",
    haftarah: "I Samuel 11:14-12:22"
  },
  { 
    id: 39, 
    name: "Chukat", 
    hebrew: "חֻקַּת",
    theme: "La vache rousse",
    torah: "Nombres 19:1 - 22:1",
    haftarah: "Michée 5:6-6:8"
  },
  { 
    id: 40, 
    name: "Balak", 
    hebrew: "בָּלָק",
    theme: "Balaam et son ânesse",
    torah: "Nombres 22:2 - 25:9",
    haftarah: "Michée 5:6-6:8"
  },
  { 
    id: 41, 
    name: "Pinchas", 
    hebrew: "פִּינְחָס",
    theme: "Le zèle de Pinchas",
    torah: "Nombres 25:10 - 29:40",
    haftarah: "I Rois 18:46-19:21"
  },
  { 
    id: 42, 
    name: "Matot", 
    hebrew: "מַטּוֹת",
    theme: "Les vœux",
    torah: "Nombres 30:2 - 32:42",
    haftarah: "I Rois 18:46-19:21"
  },
  { 
    id: 43, 
    name: "Masei", 
    hebrew: "מַסְעֵי",
    theme: "Les étapes du voyage",
    torah: "Nombres 33:1 - 36:13",
    haftarah: "I Rois 18:46-19:21"
  },
  { 
    id: 44, 
    name: "Devarim", 
    hebrew: "דְּבָרִים",
    theme: "Les paroles de Moïse",
    torah: "Deutéronome 1:1 - 3:22",
    haftarah: "Isaïe 1:1-27"
  },
  { 
    id: 45, 
    name: "Vaetchanan", 
    hebrew: "וָאֶתְחַנַּן",
    theme: "Écoute Israël",
    torah: "Deutéronome 3:23 - 7:11",
    haftarah: "Isaïe 40:1-26"
  },
  { 
    id: 46, 
    name: "Ekev", 
    hebrew: "עֵקֶב",
    theme: "Si vous écoutez",
    torah: "Deutéronome 7:12 - 11:25",
    haftarah: "Isaïe 49:14-51:3"
  },
  { 
    id: 47, 
    name: "Re'eh", 
    hebrew: "רְאֵה",
    theme: "Voyez, je place devant vous",
    torah: "Deutéronome 11:26 - 16:17",
    haftarah: "Isaïe 54:11-55:5"
  },
  { 
    id: 48, 
    name: "Shoftim", 
    hebrew: "שֹׁפְטִים",
    theme: "Les juges",
    torah: "Deutéronome 16:18 - 21:9",
    haftarah: "Isaïe 51:12-52:12"
  },
  { 
    id: 49, 
    name: "Ki Tetze", 
    hebrew: "כִּי תֵצֵא",
    theme: "Quand tu sortiras",
    torah: "Deutéronome 21:10 - 25:19",
    haftarah: "Isaïe 54:1-10"
  },
  { 
    id: 50, 
    name: "Ki Tavo", 
    hebrew: "כִּי תָבוֹא",
    theme: "Quand tu entreras",
    torah: "Deutéronome 26:1 - 29:8",
    haftarah: "Isaïe 60:1-22"
  },
  { 
    id: 51, 
    name: "Nitzavim", 
    hebrew: "נִצָּבִים",
    theme: "Vous vous tenez debout",
    torah: "Deutéronome 29:9 - 30:20",
    haftarah: "Isaïe 61:10-63:9"
  },
  { 
    id: 52, 
    name: "Vayeilech", 
    hebrew: "וַיֵּלֶךְ",
    theme: "Et il alla",
    torah: "Deutéronome 31:1 - 31:30",
    haftarah: "Jérémie 14:17-22"
  },
  { 
    id: 53, 
    name: "Haazinu", 
    hebrew: "הַאֲזִינוּ",
    theme: "Écoutez",
    torah: "Deutéronome 32:1 - 52",
    haftarah: "Isaïe 55:6-56:8"
  },
  { 
    id: 54, 
    name: "Vezot Haberachah", 
    hebrew: "וְזֹאת הַבְּרָכָה",
    theme: "Et voici la bénédiction",
    torah: "Deutéronome 33:1 - 34:12",
    haftarah: "Josué 1:1-18"
  }
];
