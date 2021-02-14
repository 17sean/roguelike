program rglike;
uses crt, slib;
type
    pmap = ^map;
    map = record
        data: string;
        next: ^map;
    end;

    ppath = ^path;
    path = record
        x, y: integer;
        next: ^path;
    end;

    pground = ^ground;
    ground = record
        x, y: integer;
        next: ^ground;
    end;

    pdoor = ^door;
    door = record
        x, y: integer;
        next: ^door;
    end;

    floor = record
        p: ppath;
        g: pground;
        d: pdoor;
    end;

    character = record
        s: char;    { Symbol }
        x, y: integer;
        hp: integer;
        money: integer;
    end;

procedure screenCheck();
begin
    if (ScreenHeight < 20) or (Screenwidth < 75) then
    begin
        clrscr;
        GotoXY((ScreenWidth div 2) - 15, ScreenHeight div 2);
        write('resize to 80x24');
        delay(2000);
        clrscr;
        halt(1);
    end;
end;

{ MAP }
procedure parseM(var first: pmap; var flr: floor; var c: character);
var
    mfile: text;
    last: pmap;
    pth, tpth: ppath;
    grn, tgrn: pground;
    dr, tdr: pdoor;
    x, y: integer;
begin
    if not DFE('map.txt') then
        halt(1);

    y := 1;
    first := nil;
    pth := nil;
    grn := nil;
    dr := nil;
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
                '@':
                begin
                    c.x := x;
                    c.y := y;
                end;

                '#':
                begin
                    new(tpth);
                    tpth^.next := pth;
                    tpth^.x := x;
                    tpth^.y := y;
                    pth := tpth;
                end;

                '.':
                begin
                    new(tgrn);
                    tgrn^.next := grn;
                    tgrn^.x := x;
                    tgrn^.y := y;
                    grn := tgrn;
                end;

                '+':
                begin
                     new(tdr);
                     tdr^.next := dr;
                     tdr^.x := x;
                     tdr^.y := y;
                     dr := tdr;
                end;
            end;

            x += 1;
        end;
        last^.next := nil;
        y += 1;
    end;
    close(mfile);
    flr.p := pth;
    flr.g := grn;
    flr.d := dr;
end;

procedure showM(m: pmap);
var
    y: integer;
begin
    y := 1;
    while m <> nil do
    begin
        GotoXY(1, y);
        write(m^.data);
        m := m^.next;
        y += 1;
    end;
end;
{ /MAP }

{ Character }
procedure showC(c: character);
begin
    GotoXY(c.x, c.y);
    write(c.s);
end;

procedure hideC(c: character; loc: char);
begin
    GotoXY(c.x, c.y);
    write(loc);
end;

function canIMove(flr: floor; c: character; ch: char): boolean;
begin
    case ch of      { count x, y }
        'w': c.y -= 1;
        'a': c.x -= 1;
        's': c.y += 1;
        'd': c.x += 1;
    end;
    while flr.p <> nil do       { Check path }
    begin
        if (flr.p^.x = c.x) and (flr.p^.y = c.y) then
        begin
            CanIMove := true;
            exit;
        end;
        flr.p := flr.p^.next;
    end;
    while flr.g <> nil do       { Check ground }
    begin
        if (flr.g^.x = c.x) and (flr.g^.y = c.y) then
        begin
            CanIMove := true;
            exit;
        end;
        flr.g := flr.g^.next;
    end;
    while flr.d <> nil do       { Check door }
    begin
        if (flr.d^.x = c.x) and (flr.d^.y = c.y) then
        begin
            CanIMove := true;
            exit;
        end;
        flr.d := flr.d^.next;
    end;
    canIMove := false;
end;

function whereAmI(flr: floor; c: character): char;
begin
    while flr.p <> nil do
    begin
        if (flr.p^.x = c.x) and (flr.p^.y = c.y) then
        begin
            whereAmI := '#';
            exit;
        end;
        flr.p := flr.p^.next;
    end;
    while flr.g <> nil do
    begin
        if (flr.g^.x = c.x) and (flr.g^.y = c.y) then
        begin
            whereAmI := '.';
            exit;
        end;
        flr.g := flr.g^.next;
    end;
    while flr.d <> nil do
    begin
        if (flr.d^.x = c.x) and (flr.d^.y = c.y) then
        begin
            whereAmI := '+';
            exit;
        end;
        flr.d := flr.d^.next;
    end;
    WhereAmI := #0;
end;

procedure moveC(flr: floor; var c: character; ch: char);
var
    loc: char;      { Location }
begin
    if not canIMove(flr, c, ch) then
        exit;
    loc := whereAmI(flr, c);
    hideC(c, loc);
    case ch of
        'w': c.y -= 1;
        'a': c.x -= 1;
        's': c.y += 1;
        'd': c.x += 1;
    end;
    showC(c);
end;

procedure handleKey(flr: floor; var c: character);
var
    ch: char;
begin
    ch := ReadKey;
    case ch of
        'w','a','s','d': moveC(flr, c, ch);
        #27:
        begin 
            clrscr;
            halt;
        end;
    end;
end;
{ /Character }

procedure init(var m: pmap; var flr: floor; var c: character);
begin
    parseM(m, flr, c);
    c.s := '@';
end;

var
    m: pmap;
    flr: floor;
    c: character;
begin
    screenCheck();
    clrscr;
    init(m, flr, c);
    showM(m);
    while true do
    begin
        if KeyPressed then
            handleKey(flr, c);
        delay(50);
    end;
end.
