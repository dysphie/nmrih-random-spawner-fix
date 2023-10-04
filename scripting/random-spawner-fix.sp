
#include <dhooks>

int offs_m_iSpawnWeights;

public Plugin myinfo =
{
    name = "Random Spawner Fix",
    author = "Dysphie",
    description = "Fixes random spawners always spawning the same items in 1.13.4",
    version = "1.0.0",
    url = "https://github.com/dysphie/nmrih-random-spawner-fix"
};

public void OnPluginStart()
{
	char gameVersion[32];
	FindConVar("nmrih_version").GetString(gameVersion, sizeof(gameVersion));
	if (!StrEqual(gameVersion, "1.13.4")) {
		SetFailState("This plugin is only needed in NMRiH 1.13.4");
	}

	GameData gamedata = new GameData("random-spawner-fix.games");
	if (!gamedata) SetFailState("Failed to find gamedata/random-spawner-fix.games.txt");

	offs_m_iSpawnWeights = gamedata.GetOffset("CRandom_Spawner::m_iSpawnWeights");
	if (offs_m_iSpawnWeights == -1)
	{
		SetFailState("Couldn't find CRandom_Spawner::m_iSpawnWeights in gamedata file");
	}

	Detour(gamedata, "CRandom_Spawner::NormalizeValues", CRandom_Spawner__NormalizeValues, Hook_Pre);
	delete gamedata
}

void Detour(GameData gamedata, const char[] key, DHookCallback callback, HookMode mode = Hook_Post)
{
	DynamicDetour detour = DynamicDetour.FromConf(gamedata, key);
	detour.Enable(mode, callback);
	delete detour;
}

MRESReturn CRandom_Spawner__NormalizeValues(int spawner)
{
	int total = 0;
	for (int i = 0; i < 85; i++)
	{
		total += GetEntData(spawner, offs_m_iSpawnWeights + i * 4);
	}

	if (total > 100)
	{
		for (int i = 0; i < 255; i++)
		{
			int offs   = offs_m_iSpawnWeights + i * 4;
			int weight = GetEntData(spawner, offs);
			SetEntData(spawner, offs, RoundToCeil(weight * (100.0 / total)));
		}
	}

	return MRES_Supercede;
}