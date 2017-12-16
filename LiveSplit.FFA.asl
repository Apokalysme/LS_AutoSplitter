state("bgb"){}
state("gambatte") {}
state("gambatte_qt") {}

startup
{
	settings.Add("helmet", true, "Helmet");
	settings.Add("cure", true, "Cure");
	settings.Add("hydra", true, "Hydra");
	settings.Add("coffin", true, "Coffin");
	settings.Add("lee", true, "Lee");
	settings.Add("blizzard", true, "Blizzard");
	settings.Add("swordskip", true, "Sword Skip");
	settings.Add("snowskip", true, "Snow Skip");
	settings.Add("aegis", true, "Aegis");
	settings.Add("julius1", true, "Julius 1");
	settings.Add("julius2", true, "Julius 2");
	settings.Add("julius3", true, "Julius 3");
	
	vars.stopwatch = new Stopwatch();
	
	vars.timer_OnStart = (EventHandler)((s, e) =>
    {
        vars.splits = vars.GetSplitList(vars.musicMode.Current);
    });
    timer.OnStart += vars.timer_OnStart;

    vars.wramTarget = new SigScanTarget(-0x20, "05 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 ?? ?? ?? ?? ?? ?? ?? ?? F8 00 00 00"); //gambatte

    vars.FindWRAM = (Func<Process, int, IntPtr>)((proc, ptr) => 
    {
        if (ptr != 0) //bgb
            return proc.ReadPointer(proc.ReadPointer(proc.ReadPointer((IntPtr)ptr) + 0x34) + 0xC0) + 0xC000;
        else //gambatte
        {
            print("[Autosplitter] Scanning memory");
            var wramPtr = IntPtr.Zero;

            foreach (var page in proc.MemoryPages())
            {
                var scanner = new SignatureScanner(proc, page.BaseAddress, (int)page.RegionSize);

                if (wramPtr == IntPtr.Zero)
                    wramPtr = scanner.Scan(vars.wramTarget);

                if (wramPtr != IntPtr.Zero)
                    break;
            }

            if (wramPtr != IntPtr.Zero)
                return proc.ReadPointer(wramPtr);
            else
                return IntPtr.Zero;
        }
    });
	
	vars.GetWatcherList = (Func<IntPtr, MemoryWatcherList>)((wramOffset) =>
    {
        return new MemoryWatcherList
		{
			// MapRef address : 0xC400
			new MemoryWatcher<short>(wramOffset + 0x400) { Name = "mapRef" },
			// OldMapRef address : 0xC402
			new MemoryWatcher<short>(wramOffset + 0x402) { Name = "oldMapRef" },
			// HelmetEquiped address : 0xD6EA
			new MemoryWatcher<byte>(wramOffset + 0x16EA) { Name = "helmetEquiped" },
			// CureStatus address : 0xD6D5
			new MemoryWatcher<byte>(wramOffset + 0x16d5) { Name = "cureStatus" },
			// SleepStatus address : 0xD6D7
			new MemoryWatcher<byte>(wramOffset + 0x16d7) { Name = "sleepStatus" },
			// CompanionCode address : 0xD7D0
			new MemoryWatcher<byte>(wramOffset + 0x17d0) { Name = "companionCode" },
			// Boss HP (msb) address : 0xD3F5
			new MemoryWatcher<byte>(wramOffset + 0x13f5) { Name = "bossHPmsb" },
			// Boss Ref address : 0xD438
			new MemoryWatcher<byte>(wramOffset + 0x1438) { Name = "bossRef" },
			
			// G Tile address : 0x9C42 (that's why we substract 0xC000)
			new MemoryWatcher<byte>(wramOffset - 0xC000 + 0x9c42) { Name = "Gtile" },
			
			new MemoryWatcher<byte>(wramOffset + 0xEFF) { Name = "resetCheck" },
            new MemoryWatcher<short>(wramOffset + 0x1B95) { Name = "gameState" },
			
			// Inventory addresses : from 0xD6C5 to 0xD6D4
			new MemoryWatcher<byte>(wramOffset + 0x16c5) { Name = "inventorySlot1" },
			new MemoryWatcher<byte>(wramOffset + 0x16c6) { Name = "inventorySlot2" },
			new MemoryWatcher<byte>(wramOffset + 0x16c7) { Name = "inventorySlot3" },
			new MemoryWatcher<byte>(wramOffset + 0x16c8) { Name = "inventorySlot4" },
			new MemoryWatcher<byte>(wramOffset + 0x16c9) { Name = "inventorySlot5" },
			new MemoryWatcher<byte>(wramOffset + 0x16ca) { Name = "inventorySlot6" },
			new MemoryWatcher<byte>(wramOffset + 0x16cb) { Name = "inventorySlot7" },
			new MemoryWatcher<byte>(wramOffset + 0x16cc) { Name = "inventorySlot8" },
			new MemoryWatcher<byte>(wramOffset + 0x16cd) { Name = "inventorySlot9" },
			new MemoryWatcher<byte>(wramOffset + 0x16ce) { Name = "inventorySlot10" },
			new MemoryWatcher<byte>(wramOffset + 0x16cf) { Name = "inventorySlot11" },
			new MemoryWatcher<byte>(wramOffset + 0x16d0) { Name = "inventorySlot12" },
			new MemoryWatcher<byte>(wramOffset + 0x16d1) { Name = "inventorySlot13" },
			new MemoryWatcher<byte>(wramOffset + 0x16d2) { Name = "inventorySlot14" },
			new MemoryWatcher<byte>(wramOffset + 0x16d3) { Name = "inventorySlot15" },
			new MemoryWatcher<byte>(wramOffset + 0x16d4) { Name = "inventorySlot16" },
		};
	});
	
	vars.GetSplitList = (Func<int, List<Tuple<string, List<Tuple<string, int>>>>>)((flag) =>
    {
        var list = new List<Tuple<string, List<Tuple<string, int>>>>
        {
			// Split when Iron Helmet is equiped (0x28 is for Iron Helmet)
            Tuple.Create("helmet", new List<Tuple<string, int>> { Tuple.Create("helmetEquiped", 0x28) }),
			
			// Split when when acquire Cure Magic
            Tuple.Create("cure", new List<Tuple<string, int>> { Tuple.Create("cureStatus", 0x01) }),
			
			// Split when Hydra die in Hydra MapRef (0x778F is the end of death animation)
            Tuple.Create("hydra", new List<Tuple<string, int>> { Tuple.Create("mapRef", 0x778f) }),
			
			// Split when Fuji join Sumo (0x40 is for Fuji as companion) in coffins screen (0x3105)
            Tuple.Create("coffin", new List<Tuple<string, int>> { Tuple.Create("companionCode", 0x40), Tuple.Create("mapRef", 0x3105)}),
			
			// Split when Lee die in Lee MapRef (0x4183)
            Tuple.Create("lee", new List<Tuple<string, int>> { Tuple.Create("mapRef", 0x4183), Tuple.Create("companionCode", 0x40) }),
			
			// <WIP>
			// Split when at least one inventory slot correspond to Blizzard Item
            Tuple.Create("blizzard", new List<Tuple<string, int>> { Tuple.Create("inventorySlot1", 0x91), Tuple.Create("inventorySlot2", 0x91), Tuple.Create("inventorySlot3", 0x91), Tuple.Create("inventorySlot4", 0x91), Tuple.Create("inventorySlot5", 0x91), Tuple.Create("inventorySlot6", 0x91), Tuple.Create("inventorySlot7", 0x91), Tuple.Create("inventorySlot8", 0x91), Tuple.Create("inventorySlot9", 0x91), Tuple.Create("inventorySlot10", 0x91), Tuple.Create("inventorySlot11", 0x91), Tuple.Create("inventorySlot12", 0x91), Tuple.Create("inventorySlot13", 0x91), Tuple.Create("inventorySlot14", 0x91), Tuple.Create("inventorySlot15", 0x91), Tuple.Create("inventorySlot16", 0x91) }),
			// </WIP>
			
			// Split after screen transition of OoB
            Tuple.Create("swordskip", new List<Tuple<string, int>> { Tuple.Create("mapRef", 0x260d) }),
			
			// Split after screen transition of SnowMan skip
            Tuple.Create("snowskip", new List<Tuple<string, int>> { Tuple.Create("oldMapRef", 0x7101), Tuple.Create("mapRef", 0x7201) }),
			
			// Split on screen transition before julius speech
			Tuple.Create("aegis", new List<Tuple<string, int>> { Tuple.Create("oldMapRef", 0x510f), Tuple.Create("mapRef", 0x500f)}),
			
			// Split when all 3 julius clones are dead
			Tuple.Create("julius1", new List<Tuple<string, int>> { Tuple.Create("mapRef", 0x6781), Tuple.Create("bossRef", 0x00) }),
            
			// Split when Julius 2 (boss Ref 0x89) dies (msb of HP address to 0xff and mapRef change to 0x6781)
            Tuple.Create("julius2", new List<Tuple<string, int>> { Tuple.Create("mapRef", 0x6781), Tuple.Create("bossRef", 0x89), Tuple.Create("bossHPmsb", 0xff) }),
						
			// Split when you loose control of Sumo after defeating the last boss
            Tuple.Create("julius3", new List<Tuple<string, int>> { Tuple.Create("mapRef", 0x508f) }),
			
        };
		return list;
	});
}

init
{
    vars.memorySize = modules.First().ModuleMemorySize;

    vars.wramOffset = IntPtr.Zero;
    vars.musicMode = new MemoryWatcher<byte>(IntPtr.Zero);
    vars.watchers = new MemoryWatcherList();
    vars.splits = new List<Tuple<string, List<Tuple<string, int>>>>();

    vars.stopwatch.Restart();
}

update
{
	if (vars.stopwatch.ElapsedMilliseconds > 1500)
	{
        switch ((int)vars.memorySize)
        {
            case 1691648: //bgb (1.5.1)
				print("Test - BGB 1.5.1");
                vars.wramOffset = vars.FindWRAM(game, 0x55BC7C);
                break;
            case 1699840: //bgb (1.5.2)
				print("Test - BGB 1.5.2");
                vars.wramOffset = vars.FindWRAM(game, 0x55DCA0);
                break;
            case 1736704: //bgb (1.5.3/1.5.4)
				print("Test - BGB 1.5.3/1.5.4");
                vars.wramOffset = vars.FindWRAM(game, 0x564EBC);
                break;
            case 14290944: //gambatte-speedrun (r600)
            case 14180352: //gambatte-speedrun (r604)
				print("Test - Gambatte");
                vars.wramOffset = vars.FindWRAM(game, 0);
                break;
            default:
                vars.wramOffset = (IntPtr)1;
                break;
        }

        if (vars.wramOffset != IntPtr.Zero)
        {
            print("[Autosplitter] WRAM: " + vars.wramOffset.ToString("X8"));
            vars.watchers = vars.GetWatcherList(vars.wramOffset);
            vars.musicMode = new MemoryWatcher<byte>(vars.wramOffset + 0x1301);

            vars.stopwatch.Reset();
        }
        else
        {
            vars.stopwatch.Restart();
            return false;
        }
	}
    else if (vars.watchers.Count == 0)
        return false;
    
    vars.musicMode.Update(game);
    vars.watchers.UpdateAll(game);
}

start
{
	// Start the run when "Girl" G Tile disappear after Fuji's name screen
	return vars.watchers["mapRef"].Current == 0x1107 && vars.watchers["Gtile"].Current != 0x40 && vars.watchers["Gtile"].Old == 0x40;
	
	// (old) Start when we get the Bear battle screen
	// return vars.watchers["mapRef"].Old == 0x1107 && vars.watchers["mapRef"].Current == 0x4701;
}

reset
{
	return vars.watchers["resetCheck"].Current > 0;
}

split
{
    foreach (var _split in vars.splits)
    {
        if (settings[_split.Item1])
        {
			var count = 0;
			
			if (_split.Item1 == "blizzard") {
				foreach (var _condition in _split.Item2)
				{
					if (vars.watchers[_condition.Item1].Current == _condition.Item2)
						count++;
				}
				
				if (count >= 1)
				{
					print("[Autosplitter] Split: " + _split.Item1);
					vars.splits.Remove(_split);
					return true;
				}
			} else {
				foreach (var _condition in _split.Item2)
				{
					if (vars.watchers[_condition.Item1].Current == _condition.Item2)
						count++;
				}
				
				if (count == _split.Item2.Count)
				{
					print("[Autosplitter] Split: " + _split.Item1);
					vars.splits.Remove(_split);
					return true;
				}
			}
		
			
		}
    }
}

shutdown
{
    timer.OnStart -= vars.timer_OnStart;
}