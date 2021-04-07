program roguelike;
uses crt, slib;
type
    pmap = ^map;
    map = record
        data: string;
        next: pmap;
    end;

    ppath = ^path;
    path = record
        x, y: integer;
        next: ppath;
    end;

    pground = ^ground;
    ground = record
        x, y: integer;
        next: pground;
    end;

    pdoor = ^door;
    door = record
        x, y: integer;
        next: pdoor;
    end;
    
    pwall = ^wall;
    wall = record
        x, y: integer;
        next: pwall;
    end;

    pbuilding = ^building;
    building = record
        x, y: integer;
        next: pbuilding;
    end;

    pitem = ^item;
    item = record
        idx: integer;
        name: string;
        dmg: integer;
        dist: integer;
        strength: integer;
        next: pitem;
    end;

    ploot = ^loot;
    loot = record
        data: item;
        x, y: integer;
        next: ploot;
    end;

    shop = record
        x, y: integer;
        heal: integer;
        gun: integer;
        healcost, guncost: integer;
    end;

    pnpcSay = ^npcSay;
    npcSay = record
        data: string;
        next: pnpcSay;
    end;
    npc = record
        x, y: integer;
        s: char;
        say: pnpcSay;
    end;

    floor = record
        p: ppath;
        g: pground;
        d: pdoor;
        w: pwall;
        b: pbuilding;
        l: ploot;
        s: shop;
        n: npc;
    end;

    character = record
        stage: integer;
        x, y: integer;
        s: char;
        hp: integer;
        money: integer;
        dmg: integer;
        melee, range: item;
    end;

    freakClass = (Demented, Hunter);
    pfreak = ^freak;
    freak = record
        x, y: integer;
        s: char;
        class: freakClass;
        hp: integer;
        dmg: integer;
        next: pfreak;
    end;

procedure screenCheck();
begin
    if (ScreenHeight < 23) or (Screenwidth < 76) then
    begin
        clrscr;
        GotoXY((ScreenWidth - 15) div 2, ScreenHeight div 2);
        write('resize to 80x24');
        delay(2000);
        clrscr;
        halt(1);
    end;
end;

procedure gameOver();
begin
    clrscr;
    GotoXY((ScreenWidth - 9) div 2, ScreenHeight div 2);
    write('Game Over');
    delay(500);
    clrscr;
    halt(1);
end;

{ MAP }
procedure showMap(var m: pmap);
var
    tm: pmap;
    y: integer;
begin
    y := 2;
    while m <> nil do
    begin
        GotoXY(1, y);
        write(m^.data);
        tm := m;
        m := m^.next;
        dispose(tm);
        y += 1;
    end;
end;

procedure clearHappen();
var
    i, j: integer;
begin
    for i := 1 to 2 do
    begin
        GotoXY(1, ScreenHeight - i);
        for j := 1 to ScreenWidth do
            write(' ');
    end;
end;
{ /MAP }

{ Items }
function getItemByIdx(itm: pitem; idx: integer): item;
begin
    while itm <> nil do
    begin
        if (idx = itm^.idx) then
        begin
            getItemByIdx := itm^;
            exit;
        end;
        itm := itm^.next;
    end;
end;

procedure loadGun(itm: pitem; var c: character; idx: integer);
begin
    if idx <= 3 then
        c.melee := getItemByIdx(itm, idx)
    else
        c.range := getItemByIdx(itm, idx);
end;

procedure unloadGun(itm: pitem; var c: character; idx: integer);
begin
    if idx <= 3 then
        c.melee := getItemByIdx(itm, 0)
    else
        c.range := getItemByIdx(itm, 0);
end;
{ /Items }

{ Parsers }
procedure parseMap(
                   var first: pmap;
                   var flr: floor;
                   var c: character;
                   var f: pfreak);
var
    mfile: text;
    last: pmap;
    p, tp: ppath;
    g, tg: pground;
    d, td: pdoor;
    w, tw: pwall;
    b, tb: pbuilding;
    l, tl: ploot;
    tf: pfreak;
    x, y: integer;
begin
    if not DFE('map.txt') then
        halt(1);

    y := 2;
    first := nil;
    p := nil;
    g := nil;
    d := nil;
    w := nil;
    b := nil;
    l := nil;
    f := nil;
    assign(mfile, 'map.txt');
    reset(mfile);
    while not EOF(mfile) do
    begin
        if first = nil then
        begin
            new(first);
            last := first;
        end
        else
        begin
            new(last^.next);
            last := last^.next;
        end;
        readln(mfile, last^.data);
        x := 1;
        while last^.data[x] <> #0 do    { Check for floors }
        begin 
            case last^.data[x] of
                '#':
                begin
                    last^.data[x] := ' ';
                    new(tp);
                    tp^.next := p;
                    tp^.x := x;
                    tp^.y := y;
                    p := tp;
                end;
                '.':
                begin
                    last^.data[x] := ' ';
                    new(tg);
                    tg^.next := g;
                    tg^.x := x;
                    tg^.y := y;
                    g := tg;
                end;
                '+':
                begin
                    new(td);
                    td^.next := d;
                    td^.x := x;
                    td^.y := y;
                    d := td;
                end;
                '|', '-':
                begin
                    new(tw);
                    tw^.next := w;
                    tw^.x := x;
                    tw^.y := y;
                    w := tw;
                end;
                'b':
                begin
                    last^.data[x] := ' ';
                    new(tb);
                    tb^.next := b;
                    tb^.x := x;
                    tb^.y := y;
                    b := tb;
                    new(tg);
                    tg^.next := g;
                    tg^.x := x;
                    tg^.y := y;
                    g := tg;
                end;
                '?':
                begin
                    last^.data[x] := ' ';
                    new(tl);
                    tl^.next := l;
                    tl^.x := x;
                    tl^.y := y;
                    l := tl;
                    new(tg);
                    tg^.next := g;
                    tg^.x := x;
                    tg^.y := y;
                    g := tg;
                end;
                '$':
                begin
                    last^.data[x] := ' ';
                    flr.s.x := x;
                    flr.s.y := y;
                end;
                'n':
                begin
                    last^.data[x] := ' ';
                    flr.n.x := x;
                    flr.n.y := y;
                end;
                '@':
                begin
                    c.x := x;
                    c.y := y;
                    c.s := last^.data[x];
                    new(tp);
                    tp^.next := p;
                    tp^.x := x;
                    tp^.y := y;
                    p := tp;
                end;
                'D', 'H':
                begin
                    new(tf);
                    tf^.next := f;
                    tf^.x := x;
                    tf^.y := y;
                    tf^.hp := 10;
                    tf^.dmg := 10;
                    tf^.s := last^.data[x];
                    last^.data[x] := ' ';
                    case tf^.s of
                        'D':
                        begin
                            tf^.class := Demented;
                            new(tg);
                            tg^.next := g;
                            tg^.x := x;
                            tg^.y := y;
                            g := tg;
                        end;
                        'H':
                        begin
                            tf^.class := Hunter;
                            new(tp);
                            tp^.next := p;
                            tp^.x := x;
                            tp^.y := y;
                            p := tp;
                        end;
                    end;
                    f := tf;
                end;
            end;
            x += 1;
        end;
        last^.next := nil;
        y += 1;
    end;
    close(mfile);
    flr.p := p;
    flr.g := g;
    flr.d := d;
    flr.w := w;
    flr.b := b;
    flr.l := l;
end;

procedure parseItems(var itm: pitem);
var
    ifile: text;
    titm: pitem;
    s: string;
begin
    if not DFE('items.txt') then
        halt(1);

    assign(ifile, 'items.txt');
    reset(ifile);
    itm := nil;
    while not EOF(ifile) do
    begin
        readln(ifile, s);
        case ParseHeader(s) of
            '~':
            begin
                new(titm);
                titm^.next := itm;
            end;
            '#': itm := titm;
            'idx': titm^.idx := SrI(ParseBody(s));
            'name': titm^.name := ParseBody(s);
            'dmg': titm^.dmg := SrI(ParseBody(s));
            'distance': titm^.dist := SrI(ParseBody(s));
            'strength': titm^.strength := SrI(ParseBody(s));
        end;
    end;
    close(ifile);
end;

procedure createSave();
var
    sfile: text;
begin
    assign(sfile, 'save.txt');
    rewrite(sfile);
    writeln(sfile, 'stage:1;');
    writeln(sfile, 'hp:100;');
    writeln(sfile, 'money:0');
    writeln(sfile, 'dmg:2;');
    writeln(sfile, 'melee:0;');
    writeln(sfile, 'range:0;');
    close(sfile);
end;

procedure parseSave(itm: pitem; var c: character);
var
    sfile: text;
    s: string;
begin
    if not DFE('save.txt') then
        createSave();

    assign(sfile, 'save.txt');
    reset(sfile);
    while not EOF(sfile) do
    begin
        readln(sfile, s);
        case ParseHeader(s) of
            'stage': c.stage := SrI(ParseBody(s));
            'hp': c.hp := SrI(ParseBody(s));
            'money': c.money := SrI(ParseBody(s));
            'dmg': c.dmg := SrI(ParseBody(s));
            'melee': loadGun(itm, c, SrI(ParseBody(s)));
            'range': loadGun(itm, c, SrI(ParseBody(s)));
        end;
    end;
    close(sfile);
end;

procedure parseNpc(var flr: floor);
var
    nfile: text;
    s: string;
    first, last: pnpcSay;
begin
    if not DFE('npc.txt') then
        exit;

    first := nil;
    assign(nfile, 'npc.txt');
    reset(nfile);
    readln(nfile, s);
    flr.n.s := s[1];
    while not EOF(nfile) do
    begin
        if first = nil then
        begin
            new(first);
            last := first;
        end
        else
        begin
            new(last^.next);
            last := last^.next;
        end;
        readln(nfile, s);
        last^.data := s;
    end;
    close(nfile);
    flr.n.say := first;
end;
{ /Parsers }

{ Init }
procedure init(
               var m: pmap;
               var flr: floor;
               var itm: pitem;
               var c: character;
               var f: pfreak);
var
    tl: ploot;
begin
    randomize;
    TextColor(yellow);
    parseMap(m, flr, c, f);
    parseItems(itm);
    parseSave(itm, c);
    parseNpc(flr);
    tl := flr.l;
    while tl <> nil do
    begin
        tl^.data := getItemByIdx(itm, random(itm^.idx)+1);
        tl^.data.strength := random(tl^.data.strength)+1;
        tl := tl^.next;
    end;
    flr.s.heal := c.stage * 5;
    if flr.s.heal > 100 then
        flr.s.heal := 100;
    flr.s.gun := random(itm^.idx)+1;
    flr.s.healcost := flr.s.heal * 2;
    flr.s.guncost := getItemByIdx(itm, flr.s.gun).dmg * 3;
end;
{ /Init }

{ FOV }
function isCharacter(c: character; x, y: integer): boolean;
begin
    if (x = c.x) and (y = c.y) then
        isCharacter := true
    else
        isCharacter := false;
end;

function isFreak(f: pfreak; x, y: integer; var ch: char): boolean;
begin
    while f <> nil do
    begin
        if (x = f^.x) and (y = f^.y) then
        begin
            isFreak := true;
            ch := f^.s;
            exit;
        end;
        f := f^.next;
    end;
    isFreak := false;
end;

function findFreak(f: pfreak; x, y: integer; var res: pfreak): boolean;
begin
    while f <> nil do
    begin
        if (x = f^.x) and (y = f^.y) then
        begin
            findFreak := true;
            res := f;
            exit;
        end;
        f := f^.next;
    end;
    res := nil;
    findFreak := false;
end;

function isPath(flr: floor; x, y: integer): boolean;
begin
    while flr.p <> nil do
    begin
        if (x = flr.p^.x) and (y = flr.p^.y) then
        begin
            isPath := true;
            exit;
        end;
        flr.p := flr.p^.next;
    end;
    isPath := false;
end;

function isGround(flr: floor; x, y: integer): boolean;
begin
    while flr.g <> nil do
    begin
        if (x = flr.g^.x) and (y = flr.g^.y) then
        begin
            isGround := true;
            exit;
        end;
        flr.g := flr.g^.next;
    end;
    isGround := false;
end;

function isDoor(flr: floor; x, y: integer): boolean;
begin
    while flr.d <> nil do
    begin
        if (x = flr.d^.x) and (y = flr.d^.y) then
        begin
            isDoor := true;
            exit;
        end;
        flr.d := flr.d^.next;
    end;
    isDoor := false;
end;

function isWall(flr: floor; x, y: integer): boolean;
begin
    while flr.w <> nil do
    begin
        if (x = flr.w^.x) and (y = flr.w^.y) then
        begin
            isWall := true;
            exit;
        end;
        flr.w := flr.w^.next;
    end;
    if isDoor(flr, x, y) then
    begin
        isWall := true;
        exit;
    end;
    isWall := false;
end;

procedure showPath(flr: floor; c: character; f: pfreak);
var
    ch: char;
    i, j, x, y: integer;
begin
    x := c.x - 1;
    y := c.y - 1;
    for i := 0 to 2 do
        for j := 0 to 2 do
        begin
            if isPath(flr, x + j, y + i) then
            begin
                GotoXY(x + j, y + i);
                write('#');
            end;
            if isDoor(flr, x + j, y + i) then
            begin
                GotoXY(x + j, y + i);
                write('+');
            end;
            if isFreak(f, x + j, y + i, ch) then
            begin
                GotoXY(x + j, y + i);
                write(ch);
            end;
        end;
    GotoXY(c.x, c.y);
    write(c.s);
end;

function isLoot(flr: floor; x, y: integer; var l: ploot): boolean;
begin
    while flr.l <> nil do
    begin
        if (x = flr.l^.x) and (y = flr.l^.y) then
        begin
            l := flr.l;
            isLoot := true;
            exit;
        end;
        flr.l := flr.l^.next;
    end;
    isLoot := false;
end;

function whatXY(flr: floor; f: pfreak; x, y: integer): char;
var
    l: ploot;
    ch: char;
begin
    if (x = flr.s.x) and (y = flr.s.y) then
    begin
        whatXY := '$';
        exit;
    end;
    if (x = flr.n.x) and (y = flr.n.y) then
    begin
        whatXY := flr.n.s;
        exit;
    end;
    if isFreak(f, x, y, ch) then
    begin
        whatXY := ch;
        exit;
    end;
    if isLoot(flr, x, y, l) then
    begin
        whatXY := '?';
        exit;
    end;
    if isDoor(flr, x, y) then
    begin
        whatXY := '+';
        exit;
    end;
    if isPath(flr, x, y) then
    begin
        whatXY := '#';
        exit;
    end;
    if isGround(flr, x, y) then
    begin
        whatXY := '.';
        exit;
    end;
    whatXY := #0;
end;

function isBuilding(flr: floor; x, y: integer): boolean;
begin
    while flr.b <> nil do
    begin
        if (x = flr.b^.x) and (y = flr.b^.y) then
        begin
            isBuilding := true;
            exit;
        end;
        flr.b := flr.b^.next;
    end;
    isBuilding := false;
end;

function findBuilding(flr: floor; c: character): boolean;
var
    x, y: integer;
begin
    if not isGround(flr, c.x, c.y) then
    begin
        findBuilding := false;
        exit;
    end;

    y := c.y;
    while not isWall(flr, c.x, y) do     { top }
    begin
        x := c.x;
        while not isWall(flr, x, y) do       { left }
        begin
            if isBuilding(flr, x, y) then
            begin
                findBuilding := true;
                exit;
            end;
            x -= 1;
        end; 
        x := c.x + 1;
        while not isWall(flr, x, y) do       { right }
        begin
            if isBuilding(flr, x, y) then
            begin
                findBuilding := true;
                exit;
            end;
            x += 1;
        end;
        y -= 1;
    end;
    y := c.y + 1;
    while not isWall(flr, c.x, y) do     { bottom }
    begin
        x := c.x;
        while not isWall(flr, x, y) do       { left }
        begin
            if isBuilding(flr, x, y) then
            begin
                findBuilding := true;
                exit;
            end;
            x -= 1;
        end; 
        x := c.x + 1;
        while not isWall(flr, x, y) do       { right }
        begin
            if isBuilding(flr, x, y) then
            begin
                findBuilding := true;
                exit;
            end;
            x += 1;
        end;
        y += 1;
    end;
    findBuilding := false;
end;

procedure showBuilding(flr: floor; c: character; f: pfreak);
var
    x, y: integer;
begin
    y := c.y;
    while not isWall(flr, c.x, y) do     { top }
    begin
        x := c.x;
        while not isWall(flr, x, y) do         { left }
        begin
            GotoXY(x, y);
            write(whatXY(flr, f, x, y));
            x -= 1;
        end; 
        x := c.x + 1;
        while not isWall(flr, x, y) do         { right }
        begin
            GotoXY(x, y);
            write(whatXY(flr, f, x, y));
            x += 1;
        end;
        y -= 1;
    end;
    y := c.y + 1;
    while not isWall(flr, c.x, y) do     { bottom }
    begin
        x := c.x;
        while not isWall(flr, x, y) do          { left }
        begin
            GotoXY(x, y);
            write(whatXY(flr, f, x, y));
            x -= 1;
        end; 
        x := c.x + 1;
        while not isWall(flr, x, y) do          { right }
        begin
            GotoXY(x, y);
            write(whatXY(flr, f, x, y));
            x += 1;
        end;
        y += 1;
    end;
    GotoXY(c.x, c.y);
    write(c.s);
end;

procedure hideBuilding(flr: floor);
var
    x, y: integer;
begin
    while flr.b <> nil do
    begin
        y := flr.b^.y;
        while not isWall(flr, flr.b^.x, y) do   { top }
        begin
            x := flr.b^.x;
            while not isWall(flr, x, y) do          { left }
            begin
                GotoXY(x, y);
                write(' ');
                x -= 1;
            end; 
            x := flr.b^.x + 1;
            while not isWall(flr, x, y) do          { right }
            begin
                GotoXY(x, y);
                write(' ');
                x += 1;
            end;
            y -= 1;
        end;
        y := flr.b^.y + 1;
        while not isWall(flr, flr.b^.x, y) do   { bottom }
        begin
            x := flr.b^.x;
            while not isWall(flr, x, y) do          { left }
            begin
                GotoXY(x, y);
                write(' ');
                x -= 1;
            end; 
            x := flr.b^.x + 1;
            while not isWall(flr, x, y) do          { right }
            begin
                GotoXY(x, y);
                write(' ');
                x += 1;
            end;
            y += 1;
        end;
        flr.b := flr.b^.next;
    end;
end;

procedure checkFov(flr: floor; c: character; f: pfreak);
begin
    showPath(flr, c, f);
    if findBuilding(flr, c) then
        showBuilding(flr, c, f)
    else if isDoor(flr, c.x, c.y) then
        hideBuilding(flr);
end;
{ /FOV }

{ Loot }
procedure removeL(var flr: floor; var t: ploot);
var
    pp: ^ploot;
begin
    pp := @flr.l;
    while pp^ <> t do
        pp := @(pp^^.next);
    pp^ := pp^^.next;
    dispose(t);
end;

procedure lootInterface(l: loot);
var
    x, y: integer;
begin
    x := (ScreenWidth - 23) div 3;
    y := ScreenHeight - 2;
    GotoXY(x, y);
    write(l.data.name, ' with ', l.data.strength, ' strength');
    GotoXY(x, y+1);
    write('F) Take it'); 
end;

procedure lootMenu(var flr: floor; var t: ploot; var c: character);
var
    ch: char;
begin
    lootInterface(t^);
    ch := ReadKey;
    clearHappen();
    if not (ch in ['f', 'F']) then
        exit;
    { If already have }
    if (t^.data.idx = c.melee.idx) or (t^.data.idx = c.range.idx) then
    begin
        if t^.data.idx <= 3 then
            c.melee.strength += t^.data.strength
        else
            c.range.strength += t^.data.strength;
        removeL(flr, t);
        exit;
    end
    else if t^.data.idx <= 3 then   { If new }
        c.melee := t^.data
    else
        c.range := t^.data;
    removeL(flr, t);
end;
{ /Loot }

{ Shop }
procedure shopInterface(flr: floor; itm: pitem);
var
    x, y: integer;
begin
    x := (ScreenWidth - 23) div 3;
    y := ScreenHeight - 2;
    GotoXY(x, y);
    write('1) ', flr.s.heal, ' Heal: ', flr.s.healcost);
    GotoXY(x, y+1);
    write('2) ', getItemByIdx(itm, flr.s.gun).name, ': ', flr.s.guncost); 
end;

procedure shopMenu(flr: floor; itm: pitem; var c: character);
var
    ch: char;
    success: boolean;
begin
    success := false;
    shopInterface(flr, itm);
    ch := ReadKey;
    clearHappen();
    case ch of
        '1':
        begin
            if flr.s.healcost <= c.money then
            begin
                c.hp += flr.s.heal;
                if c.hp > 100 then
                    c.hp := 100;
                c.money -= flr.s.healcost;
                success := true;
            end;
        end;
        '2':
        begin
            if flr.s.guncost <= c.money then
            begin
                loadGun(itm, c, flr.s.gun);
                c.money -= flr.s.guncost;
                success := true;
            end;
        end;
        else
            exit;
    end;
    if success then
    begin
        GotoXY((ScreenWidth - 23) div 3, ScreenHeight - 2);
        write('Success');
        delay(1000);
    end
    else
    begin
        GotoXY((ScreenWidth - 23) div 3, ScreenHeight - 2);
        write('You haven`t enough money');
        delay(2000);
    end;
    clearHappen();
end;
{ /Shop }

{ NPC }
procedure npcTalk(flr: floor);
var
    i, len: integer;
begin
    while flr.n.say <> nil do
    begin
        clearHappen();
        if KeyPressed then
            exit;
        len := length(flr.n.say^.data);
        GotoXY((ScreenWidth - 23) div 3, ScreenHeight - 2);
        for i := 1 to len do
        begin
            write(flr.n.say^.data[i]);
            delay(150);
        end;
        delay(500);
        for i := len downto 1 do   { erase words }
        begin
            write(' '#8#8);
            delay(50);
        end;
        flr.n.say := flr.n.say^.next;
    end;
end;
{ /NPC }

{ Messages }
procedure hitMsgC(dmg: integer; mr, nc: char);
begin
    GotoXY((ScreenWidth - 23) div 3, ScreenHeight - 2);
    if dmg <= 0 then
    begin
        write('You didn`t hit');
        delay(1000);
        exit;
    end;
    if nc = 'c' then
    begin
        write('Critical hit! Damage ', dmg);
        exit;
    end;
    case mr of
        'm': write('You attacked. Damage ', dmg);
        'r': write('You fired. Damage ', dmg);
    end;
    delay(1000);
end;

procedure deadMsgC(f: freak);
begin
    GotoXY((ScreenWidth - 23) div 3, ScreenHeight - 1);
    write('You died by ', f.class);
    delay(2000);
end;

procedure noGunMsgC();
begin
    GotoXY((ScreenWidth - 23) div 3, ScreenHeight - 1);
    write('You haven''t any gun');
    delay(2000);
end;

procedure brokenGunMsgC();
begin
    GotoXY((ScreenWidth - 23) div 3, ScreenHeight - 1);
    write('Your weapon is broken');
    delay(2000);
end;

procedure hitMsgF(dmg: integer; f: freak);
begin
    GotoXY((ScreenWidth - 23) div 3, ScreenHeight - 2);
    if dmg <= 0 then
    begin
        write(f.class, ' didn`t hit');
        exit;
    end;
    write(f.class, ' attacked. Damage ', dmg);
    delay(1000);
end;

procedure deadMsgF(f: freak);
begin
    GotoXY((ScreenWidth - 23) div 3, ScreenHeight - 1);
    write(f.class, ' is dead');
    delay(1000);
end;
{ /Messages }

{ Freak }
procedure removeF(var f, t: pfreak);
var
    pp: ^pfreak;
begin
    pp := @f;
    while pp^ <> t do
        pp := @(pp^^.next);
    pp^ := pp^^.next;
    dispose(t);
end;

procedure combatF(flr: floor; var c: character; f: freak);
var
    dmg: integer;
begin
    if random(25) = 0 then    { chance for miss hit }
    begin
        hitMsgF(0, f);
        exit;
    end;

    dmg := f.dmg - random(f.dmg div 2);   { random damage }
    c.hp -= dmg;
    hitMsgF(dmg, f);
    if c.hp <= 0 then
    begin
        deadMsgC(f);
        gameOver();
    end;
end;

function canFMove(flr: floor; c: character; all: pfreak; f: freak; ch: char)
                                                                    : boolean;
begin
    case ch of      { count x, y }
        'w': f.y -= 1;
        'a': f.x -= 1;
        's': f.y += 1;
        'd': f.x += 1;
    end;
    if (f.x = flr.s.x) and (f.y = flr.s.y) then    { Shop }
    begin
        CanFMove := false;
        exit;
    end;
    if (f.x = flr.n.x) and (f.y = flr.n.y) then    { NPC }
    begin
        CanFMove := false;
        exit;
    end;
    while all <> nil do          { Check freaks }
    begin
        if (f.x = all^.x) and (f.y = all^.y) then
        begin
            CanFMove := false;
            exit;
        end;
        all := all^.next;
    end;
    while flr.d <> nil do       { Check door }
    begin
        if (f.x = flr.d^.x) and (f.y = flr.d^.y) then
        begin
            CanFMove := true;
            exit;
        end;
        flr.d := flr.d^.next;
    end;
    while flr.p <> nil do       { Check path }
    begin
        if (f.x = flr.p^.x) and (f.y = flr.p^.y) then
        begin
            CanFMove := true;
            exit;
        end;
        flr.p := flr.p^.next;
    end;
    while flr.g <> nil do       { Check ground }
    begin
        if (f.x = flr.g^.x) and (f.y = flr.g^.y) then
        begin
            CanFMove := true;
            exit;
        end;
        flr.g := flr.g^.next;
    end;
    canFMove := false;
end;

procedure moveF(flr: floor; c: character; all: pfreak; var f: freak);
var
    ch: char;
    i, j, x, y: integer;
    found: boolean;
begin
    if random(25) = 0 then   { chance for miss move }
        exit;

    found := false;
    x := f.x - 5;
    y := f.y - 5;
    for i := 0 to 10 do
        for j := 0 to 10 do
            if isCharacter(c, x + j, y + i) then
                found := true;
    if found then
    begin
        case random(2) of
            0:
                if f.y <> c.y then
                    if f.y > c.y then
                        ch := 'w'
                    else
                        ch := 's';
            1:
                if f.x <> c.x then
                    if f.x > c.x then
                        ch := 'a'
                    else
                        ch := 'd';
        end;
    end
    else
    begin
        case random(4) of
            0: ch := 'w';
            1: ch := 'a';
            2: ch := 's';
            3: ch := 'd';
        end;
    end;
    if canFMove(flr, c, all, f, ch) then
        case ch of
            'w': f.y -= 1;
            'a': f.x -= 1;
            's': f.y += 1;
            'd': f.x += 1;
        end;
end;

procedure actionFreak(flr: floor; var c: character; var f: pfreak);
var
    tmpf: pfreak;
    i, j, x, y: integer;
    found: boolean;
begin
    tmpf := f;
    while tmpf <> nil do
    begin
        found := false;
        x := tmpf^.x - 1;
        y := tmpf^.y - 1;
        for i := 0 to 2 do
            for j := 0 to 2 do
                if isCharacter(c, x + j, y + i) then
                    found := true;
        if found then
            combatF(flr, c, tmpf^)
        else
            moveF(flr, c, f, tmpf^);
        tmpf := tmpf^.next;
    end;
end;
{ /Freak } 

{ Character }
procedure addMoney(var c: character; f: freak);
var
    money: integer;
begin
    case f.class of
        Demented: money := 2;
        Hunter: money := 5;
    end;
    c.money += money;
end;

procedure meleeC(itm: pitem; var c: character; var f: pfreak);
var
    t, tmp: pfreak;     { target freak } 
    i, j, x, y, dmg: integer;
    nc: char;
begin
    if (c.melee.strength <= 0) and (c.melee.idx <> 0) then
    begin
        unloadGun(itm, c, c.melee.idx);
        brokenGunMsgC();
        clearHappen();
    end;
    if c.melee.strength <> 0 then
        c.melee.strength -= 1;
    if random(25) = 0 then   { chance for miss hit }
    begin
        hitMsgC(0, 'm', 'n');
        exit;
    end;

    t := nil;
    x := c.x - 1;
    y := c.y - 1;
    for i := 0 to 2 do
        for j := 0 to 2 do
            if findFreak(f, x + j, y + i, tmp) then
                t := tmp;
    if t = nil then     { if haven`t got target } 
    begin
        hitMsgC(0, 'm', 'n');
        exit;
    end;
    dmg := c.dmg + c.melee.dmg - random(c.melee.dmg div 2);   { random damage }
    if random(25) = 0 then   { critical hit }
    begin
        dmg *= 2;
        nc := 'c';
    end
    else
        nc := 'n';
    t^.hp -= dmg;
    hitMsgC(dmg, 'm', nc);
    if t^.hp <= 0 then
    begin
        deadMsgF(t^);
        addMoney(c, t^);
        removeF(f, t);
    end;
end;

procedure rangeC(flr: floor; itm: pitem; var c: character; var f: pfreak);
var
    t, tmp: pfreak;     { target freak } 
    i, j, x, y, dmg: integer;
    nc: char;
begin
    if (c.range.idx = 0) then
    begin
        noGunMsgC();
        exit;
    end;
    if (c.range.strength <= 0) and (c.range.idx <> 0) then
    begin
        unloadGun(itm, c, c.range.idx);
        brokenGunMsgC();
        exit;
    end;
    if c.range.strength <> 0 then
        c.range.strength -= 1;
    if random(25) = 0 then   { chance for miss hit }
    begin
        hitMsgC(0, 'r', 'n');
        exit;
    end;

    t := nil;
    x := c.x - 1;           
    y := c.y - 1;
    for i := 0 to 2 do     { if near the player }
        for j := 0 to 2 do
            if findFreak(f, x + j, y + i, tmp) then
                t := tmp;
    x := c.x;           
    y := c.y;
    for i := 1 to c.range.dist do     { vertical }
        if not isWall(flr, x, y - i) then
        begin
            if findFreak(f, x, y - i, tmp) and (t = nil) then
                t := tmp;
        end
        else
            break;
    for i := 1 to c.range.dist do
        if not isWall(flr, x, y + i) then
        begin
            if findFreak(f, x, y + i, tmp) and (t = nil) then
                t := tmp;
        end
        else
            break;
    for j := 1 to c.range.dist do      { horizontal }
        if not isWall(flr, x + j, y) then
        begin
            if findFreak(f, x + j, y, tmp) and (t = nil) then
                t := tmp;
        end
        else
            break;
    for j := 1 to c.range.dist do
        if not isWall(flr, x - j, y) then
        begin
            if findFreak(f, x - j, y, tmp) and (t = nil) then
                t := tmp;
        end
        else
            break;
    if t = nil then     { if haven`t got target } 
    begin
        hitMsgC(0, 'r', 'n');
        exit;
    end;
    dmg := c.range.dmg - random(c.range.dmg div 2);   { random damage } 
    if random(25) = 0 then   { critical hit }
    begin
        dmg *= 2;
        nc := 'c';
    end
    else
        nc := 'n';
    t^.hp -= dmg;
    hitMsgC(dmg, 'r', nc);
    if t^.hp <= 0 then
    begin
        deadMsgF(t^);
        addMoney(c, t^);
        removeF(f, t);
    end;
end;

function canIMove(var flr: floor; itm: pitem; var c: character;
                                        var f: pfreak; ch: char): boolean;
var
    tl: ploot;
    tmpf, tf: pfreak;
    x, y: integer;
begin
    x := c.x;
    y := c.y;
    tmpf := f;
    case ch of      { count x, y }
        'w', 'W': y -= 1;
        'a', 'A': x -= 1;
        's', 'S': y += 1;
        'd', 'D': x += 1;
    end;
    if (x = flr.s.x) and (y = flr.s.y) then    { Shop }
    begin
        canIMove := false;
        shopMenu(flr, itm, c);
        exit;
    end;
    if (x = flr.n.x) and (y = flr.n.y) then    { Npc }
    begin
        canIMove := false;
        npcTalk(flr);
        exit;
    end;
    if isLoot(flr, x, y, tl) then { Loot }
    begin
        CanIMove := false;
        lootMenu(flr, tl, c);
        exit;
    end;
    if findFreak(tmpf, x, y, tf) then  { Freak }
    begin
        CanIMove := false;
        meleeC(itm, c, tf);
        exit
    end;
    if isDoor(flr, x, y) then   { Door }
    begin
        CanIMove := true;
        exit;
    end;
    if isPath(flr, x, y) then   { Path }
    begin
        CanIMove := true;
        exit;
    end;
    if isGround(flr, x, y) then { Ground } 
    begin
        canIMove := true;
        exit;
    end;
    canIMove := false;
end;

procedure showC(c: character);
begin
    GotoXY(c.x, c.y);
    write(c.s);
end;

procedure hideC(flr: floor; c: character; f: pfreak);
var
    loc: char;
begin
    loc := whatXY(flr, f, c.x, c.y);
    GotoXY(c.x, c.y);
    write(loc);
end;

procedure moveC(var flr: floor; itm: pitem; var c: character;
                                                 var f: pfreak; ch: char);
begin
    if not canIMove(flr, itm, c, f, ch) then
        exit;
    hideC(flr, c, f);
    case ch of
        'w', 'W': c.y -= 1;
        'a', 'A': c.x -= 1;
        's', 'S': c.y += 1;
        'd', 'D': c.x += 1;
    end;
    showC(c);
end;

procedure showParam(c: character);
var
    i: integer;
begin
    for i := 1 to ScreenWidth do
    begin
        GotoXY(i, 1);
        write(' ');
    end;
    GotoXY(5, 1);
    write('HP: ', c.hp);
    write('  Money: ', c.money);
    write('  Inv: ', c.melee.name);
    write(' and ', c.range.name);
    write('   M: ', c.melee.dmg + c.dmg);
    write(' S: ', c.melee.strength);
    write('   R: ', c.range.dmg);
    write(' S: ', c.range.strength);
end;

procedure handleKey(var flr: floor; itm: pitem; var c: character;
                                                             var f: pfreak);
var
    ch: char;
begin
    ch := ReadKey;
    case ch of
        'w','W','a','A','s','S','d','D': moveC(flr, itm, c, f, ch);
        'e', 'E': meleeC(itm, c, f);
        'q', 'Q': rangeC(flr, itm, c, f);
        #27: gameOver();
    end;
end;
{ /Character }

var
    m: pmap;
    flr: floor;
    itm: pitem;
    c: character;
    f: pfreak;
begin
    clrscr;
    screenCheck();
    init(m, flr, itm, c, f);
    showMap(m);
    checkFov(flr, c, f);
    showParam(c);
    while true do
    begin
        if KeyPressed then
        begin
            clearHappen();
            handleKey(flr, itm, c, f);
            clearHappen();
            actionFreak(flr, c, f);
            showParam(c);
            checkFov(flr, c, f);
        end;
    end;
end.
