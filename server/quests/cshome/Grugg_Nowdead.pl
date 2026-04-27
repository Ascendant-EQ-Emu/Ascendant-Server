# Particle Effect Viewer - Grugg Nowdead (cshome)
# Lets players preview appearance effects by range

our ($Range1, $Range2);

sub EVENT_SPAWN {
	$npc->RemoveAllAppearanceEffects();
}

sub EVENT_TIMER {
	if ($timer eq "clear_effect") {
		quest::stoptimer("clear_effect");
		$npc->RemoveAllAppearanceEffects();
	}
}

sub EVENT_SAY {

	my %PA = (
		1 => [" static tiny lightning bolts along the floor", 1],
		2 => [" static tiny blue/white ball", 2],
		3 => [" static tiny blue/white fire", 3],
		4 => [" static tiny electric field wall", 4],
		5 => [" static tiny electric bolts going up", 5],
		6 => [" static tiny electric bursts", 6],
		7 => [" tiny electric burst particles", 7],
		8 => [" tiny blue/white ball burst", 8],
		9 => [" static tiny electricity from the floor", 9],
		10 => [" Nothing?", 10],
		11 => [" static tiny electric burst sphere", 11],
		12 => [" static tiny electric bolts from the floor (nice)", 12],
		13 => [" static blue/white flame sword effect", 13],
		14 => [" static green/white flame sword effect", 14],
		15 => [" static tiny light burst", 15],
		16 => [" static tiny green/white low density particles", 16],
		17 => [" static tiny red flame sword effect", 17],
		18 => [" static tiny D rotating light burst", 18],
		19 => [" static tiny green very low density particles", 19],
		20 => [" static tiny red very low density particles", 20],
		21 => [" static tiny blue very low density particles", 21],
		22 => [" small long and flat golden cloud", 22],
		23 => [" static Cleric effect", 23],
		24 => [" Ranger effect", 24],
		25 => [" static tiny green drip (rogue effect?)", 25],
		26 => [" static tiny green mist (rogue effect?)", 26],
		27 => [" small green burst of flame", 27],
		28 => [" small light burst particle", 28],
		29 => [" small green mist spray", 29],
		30 => [" small tall smoke", 30],
		31 => [" small pastel round particles", 31],
		32 => [" small green circle light bursts", 32],
		33 => [" small animated vertical light burst", 33],
		34 => [" small sphere of blue and white particle sprites", 34],
		35 => [" small vertical flame burst", 35],
		36 => [" small loose vertical flame burst", 36],
		37 => [" static small red glowing cloud", 37],
		38 => [" static tiny yellow particle fire", 38],
		39 => [" small yellow cloud burst", 39],
		40 => [" small yellow/orange flame burst", 40],
		41 => [" yellow flashy light burst", 41],
		42 => [" static tiny yellow light burst/particles aura", 42],
		43 => [" static tiny blue vertical lights forming a ring aura", 43],
		44 => [" static tiny pink/white flame", 44],
		45 => [" Nothing?", 45],
		46 => [" Nothing?", 46],
		47 => [" orange ring light bursts", 47],
		48 => [" static small vertical black smoke", 48],
		49 => [" static tiny blowing light black smoke", 49],
		50 => [" static small orange flame ring sphere", 50],
		51 => [" static tiny green particles flowing up", 51],
		52 => [" static small pink/blue flame", 52],
		53 => [" tiny pink/blue vertical flame slivers", 53],
		54 => [" static tiny pink/blue flame", 54],
		55 => [" static small white smoke puffs slow intervals", 55],
		56 => [" small black smoke ring poof", 56],
		57 => [" static small fast translucent black smoke clouds", 57],
		58 => [" small white particle swirl", 58],
		59 => [" static small yellow/white burst rounded flames", 59],
		60 => [" small white swirling particle bursts", 60],
		61 => [" static tiny green/yellow/white high density particle flow", 61],
		62 => [" static small yellow/white burst flames", 62],
		63 => [" small white star burst", 63],
		64 => [" small snowie impact particle burst", 64],
		65 => [" small blue/white cloud burst", 65],
		66 => [" flashy rotating star bursts", 66],
		67 => [" tiny white particle bursts sphere", 67],
		68 => [" small purple blowing clouds", 68],
		69 => [" small purple blowing clouds blowing towards you", 69],
		70 => [" small bubbles", 70],
		71 => [" small ZZZ", 71],
		72 => [" small light particle swirl", 72],
		73 => [" tiny light burst seconds", 73],
		74 => [" tiny blue/white particle bursts flow", 74],
		75 => [" small upward rock burst", 75],
		76 => [" small transparent black cloud burst", 76],
		77 => [" medium blue vertical cones circling the caster", 77],
		78 => [" medium large blue vertical cone", 78],
		79 => [" medium yellow/white flame burst (level up)", 79],
		80 => [" medium yellow round particles flowing up", 80],
		81 => [" medium yellow star burst spiral up around caster", 81],
		82 => [" Nothing?", 82],
		83 => [" static medium blue/white flowing smoke", 83],
		84 => [" medium dense black cloud burst", 84],
		85 => [" medium springs shooting from the ground", 85],
		86 => [" medium sprockets shooting from the ground", 86],
		87 => [" medium round electro-static bursts", 87],
		88 => [" medium black lava chunks shooting from the ground", 88],
		89 => [" static small vertical electric field", 89],
		90 => [" large lightning bolt from above to target", 90],
		91 => [" medium light burst to target", 91],
		92 => [" small purple cloud burst", 92],
		93 => [" medium black lava chunks many bursting from the ground", 93],
		94 => [" medium white particles raising and fading", 94],
		95 => [" static tiny blue/white sphere of light", 95],
		96 => [" static tiny white particle bursts sphere", 96],
		97 => [" static very tiny yellow light burst", 97],
		98 => [" tiny sideways shooting flame", 98],
		99 => [" tiny yellow light burst", 99],
		100 => [" static tiny vertical red flame sword effect", 100],
		101 => ["Water Forming on Ground (non-perma)", 180],
		102 => ["Fire Breath (Big) (non-perma)", 185],
		103 => ["Black Fire Breath (non-perma)", 186],
		104 => ["Fire Forming on Ground (non-perma)", 187],
		105 => ["Fire Blasting from Ground (non-perma)", 188],
		106 => ["Electricity Blasting from Ground (non-perma)", 189],
		107 => ["Realistic Burning Fire (non-perma)", 190],
		108 => ["Green Smoke (non-perma)", 199],
		109 => ["Green Smoke Ring at Feet (non-perma)", 200],
		110 => ["White Smoke Ring at Feet (non-perma)", 201],
		111 => ["Slow Blue/Purple/Pink Fading Smoke Cloud (non-perma)", 202],
		112 => ["White Sparkles flying upward (non-perma)", 203],
		113 => ["White Smoke Blast (non-perma)", 204],
		114 => ["Water Forming on Ground (non-perma)", 205],
		115 => ["Ice Forming on Ground (non-perma)", 206],
		116 => ["Ice Floating around Ground (non-perma)", 207],
		117 => ["White Sparkles forming on Ground (non-perma)", 208],
		118 => ["Green Fart (non-perma)", 209],
		119 => ["Yellow Sparkles eminating from Ground (perma)", 210],
		120 => ["White Sparkles eminating from Ground (perma)", 211],
		121 => ["White Smoke Emitting at Feet (perma)", 212],
		122 => ["Black Smoke Emitting at Feet (perma)", 213],
		123 => ["Yellow Sparkle Explosion (non-perma)", 214],
		124 => ["Aurora Borealis Effect from Feet (non-perma)", 215],
		125 => ["White Smoke Poof from Ground (non-perma)", 216],
		126 => ["Blue Sparks Ring at Feet (non-perma)", 217],
		127 => ["White Spark at Feet (non-perma)", 218],
		128 => ["Fire Pulse at Feet (non-perma)", 219],
		129 => ["Black Smoke Emitting at Feet (non-perma)", 220],
		130 => ["Electric Shock at Feet (non-perma)", 221],
		131 => ["Electric Strike on Body (non-perma)", 222],
		132 => ["Blue Sparkle at Feet (non-perma)", 223],
		133 => ["Small Sparkle falling from feet into ground (non-perma)", 224],
		134 => ["Small Electric field at feet (non-perma)", 225],
		135 => ["Small Electric field at feet (perma)", 226],
		136 => ["Small Directional Gust of Dark Smoke (perma)", 227],
		137 => ["Small Emitting Smoke from Feet (perma)", 228],
		138 => ["Small Fire Embers from Feet (perma)", 229],
		139 => ["Various Yellow Sparkles around Body (perma)", 230],
		140 => ["Gentle Emitting Smoke from Feet (perma)", 231],
		141 => ["Small Red Flame at Feet (non-perma)", 232],
		142 => ["Swirling Gust of Dark Smoke (non-perma)", 233],
		143 => ["Nothing Visible (?)", 234],
		144 => ["Nothing Visible (?)", 235],
		145 => ["Small Electric Pulse at Feet (non-perma)", 236],
		146 => ["Electric Strike at Feet (non-perma)", 237],
		147 => ["Small Random Electric Shock at Feet (non-perma)", 238],
		148 => ["Small Blue Gush of Smoke at Feet (non-perma)", 239],
		149 => ["Small White Gush of Smoke at Feet (non-perma)", 240],
		150 => [" static small cloud puff bursts", 330],
		151 => [" nothing?", 331],
		152 => [" static small diagonal lightning bolts", 332],
		153 => [" small white cloud burst", 333],
		154 => [" static widespread falling snow flakes", 334],
		155 => [" static widespread shooting up rocks", 335],
		156 => [" static wide orange shooting up particle ring", 336],
		157 => [" static wide dark blue shooting up particle ring", 337],
		158 => [" static wide green shooting up particle ring", 338],
		159 => [" static wide purple shooting up particle ring", 339],
		160 => [" static wide gold shooting up particle ring", 340],
		161 => [" static wide ice blue shooting up particle ring", 341],
		162 => [" static wide black shooting up particle ring", 342],
		163 => [" static wide grey shooting up particle ring", 343],
		164 => [" static wide blood red shooting up particle ring", 344],
		165 => [" static widespread raining red notes", 345],
		166 => [" static widespread small slow blue/white falling particles", 346],
		167 => [" static widespread random ground flame bursts", 347],
		168 => [" static widespread fast brown ground fog/smoke", 348],
		169 => [" static widespread fast white ground fog/smoke", 349],
		170 => [" static widespread fast light black ground fog/smoke", 350],
		171 => [" static widespread fast black ground fog/smoke", 351],
		172 => [" static widespread fast purple ground fog/smoke", 352],
		173 => [" static widespread fast and heavy lightning", 353],
		174 => [" static widespread white tornado clouds", 354],
		175 => [" static widespread poison clouds", 355],
		176 => [" static widespread green bee clouds", 356],
		177 => [" static widespread blue/white pulsing orbs particles in a ball shape", 357],
		178 => [" static small fast thick black smoke", 358],
		179 => [" static small flame sparks", 359],
		180 => [" static medium tall skinny white flame", 360],
		181 => [" small pink sparkler bursts", 361],
		182 => [" nothing?", 362],
		183 => [" medium flame ring burst", 363],
		184 => [" medium firework burst", 364],
		185 => [" medium smoke ring around target", 365],
		186 => [" static medium flame ring", 366],
		187 => [" static medium fast flame sparks", 367],
		188 => [" medium flame burst", 368],
		189 => [" medium light white smoke", 369],
		190 => [" medium grey smoke ring around target", 370],
		191 => [" medium smoke cloud from hands", 371],
		192 => [" medium quick smoke puffs ring around target", 372],
		193 => [" medium fast smoke puffs ring around target", 373],
		194 => [" tiny blue/white spinning smoke ball", 374],
		195 => [" tiny blue/white spinning smoke ball short duration", 375],
		196 => [" small blue/white spinning smoke ball short duration", 376],
		197 => [" small green spinning smoke ball", 377],
		198 => [" small blue/white spinning smoke ball", 378],
		199 => [" medium blue/white spinning smoke ball", 379],
		200 => [" medium light smoke ring around target", 380],
		201 => [" medium light smoke puffs ring around target", 381],
		202 => [" medium fire burst", 382],
		203 => [" medium black smoke cloud burst", 383],
		204 => [" nothing?", 384],
		205 => [" medium light smoke ring around target", 385],
		206 => [" medium flame ring around target", 386],
		207 => [" medium smoke puff ring around target", 387],
		208 => [" static small purple cloud puff bursts", 388],
		209 => [" static widespread overhead swirling black clouds", 389],
		210 => [" static widespread huge ice shard particles", 390],
		211 => [" static widespread raining rainbow notes", 391],
		212 => [" static widespread orange orb particles", 392],
		213 => [" static widespread green/blue/red orb particles", 393],
		214 => [" static widespread pink/purple orb particles", 394],
		215 => [" static widespread grey/white orb particles", 395],
		216 => [" static widespread brown orb particles", 396],
		217 => [" static small white ball of dense bubble particles", 397],
		218 => [" static small blue/white glowing smoke ball", 398],
		219 => [" static tiny white diagonal shooting particles", 399],
		220 => [" static small fire", 400],
		221 => [" nothing?", 401],
		222 => [" static small fire smoke", 402],
		223 => [" static small campfire like flame", 403],
		224 => [" static small campfire sparks", 404],
		225 => [" static small inner campfire flame", 405],
		226 => [" static small campfire electric sparks", 406],
		227 => [" static medium very low density fire sparks that shoot far", 407],
		228 => [" static small white glowing smoke ball", 408],
		229 => [" static small purple smoke ball", 409],
		230 => [" static small ash particles", 410],
		231 => [" static small white/blue smoke ball", 411],
		232 => [" static small vertical white smoke", 412],
		233 => [" static small purple cone shaped smoke", 413],
		234 => [" static small purple smoke ball", 414],
		235 => [" static small fast purple shooting particles", 415],
		236 => [" static small fast smoke", 416],
		237 => [" static small fire", 417],
		238 => [" static small pink fire ball", 418],
		239 => [" static small fire sparks", 419],
		240 => [" static small very low density fire sparks that shoot far", 420],
		241 => [" static small aqua/pink/purple/white flame", 421],
		242 => [" static medium campfire like flame", 422],
		243 => [" static medium campfire smoke", 423],
		244 => [" static small diagonal fire particles slow", 424],
		245 => [" static small diagonal fire particles slower", 425],
		246 => [" static small bouncy fire particles", 426],
		247 => [" static small bouncy fire particles", 427],
		248 => [" static tiny circular fire ring that is vertical", 428],
		249 => [" static small circular fire ring that is vertical", 429],
		250 => [" static small diagonal fire particles", 430],
		251 => [" static small ball of fire particles", 431],
		252 => [" static small blue and yellow rotating smoke rings", 432],
		253 => [" static small blue and yellow particle rings that loop", 433],
		254 => [" static small blue and yellow flame sword weapon particles", 434],
		255 => [" static small blue and yellow flame wall weapon particles", 435],
		256 => [" static small blue and brown blocky smoke weapon particles", 436],
	);

	my $Link4 = quest::saylink("Effect", 1);

	if ($text =~ /hail/i) {
		my $Link1 = quest::saylink("1-100", 1);
		my $Link2 = quest::saylink("101-200", 1);
		my $Link3 = quest::saylink("201-400", 1);
		$client->Message(10, "Set your visible effects range menu:");
		$client->Message(10, "  $Link1");
		$client->Message(10, "  $Link2");
		$client->Message(10, "  $Link3");
	}
	elsif ($text =~ /^1-100$/i) {
		$Range1 = 1;
		$Range2 = 100;
		$client->Message(10, "Range has been set, type [$Link4]");
	}
	elsif ($text =~ /^101-200$/i) {
		$Range1 = 101;
		$Range2 = 200;
		$client->Message(10, "Range has been set, type [$Link4]");
	}
	elsif ($text =~ /^201-400$/i) {
		$Range1 = 201;
		$Range2 = 400;
		$client->Message(10, "Range has been set, type [$Link4]");
	}
	elsif ($text =~ /^effect$/i) {
		if (!$Range1 || !$Range2) {
			$client->Message(13, "Please select a range first.");
			return;
		}
		my $n = 1;
		while ($PA{$n}) {
			if ($PA{$n}[1] <= $Range2 && $PA{$n}[1] >= $Range1) {
				my $link = quest::saylink($PA{$n}[1], 1, $PA{$n}[0]);
				$client->Message(10, "$PA{$n}[1] $link");
			}
			$n++;
		}
	}
	elsif ($text =~ /^\d+$/) {
		quest::stoptimer("clear_effect");
		$npc->SendAppearanceEffect(int($text));
		$client->Message(10, "Playing effect: $text (clearing in 5s)");
		quest::settimer("clear_effect", 5);
	}
}
