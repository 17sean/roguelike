program rglike;
uses crt, slib;
type
    pmap = ^map;
    map = record
        data: string;
        next: ^map;
    end;

    character = record
        s: char;    { Symbol }
        x, y: integer;
        hp: integer;
        money: integer;
    end;

{ MAP }
procedure parseM(var first: pmap);
var
    mfile: text;
    last: pmap;
begin
    if not DFE('map.txt') then
        halt(1);

    first := nil;
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
        last^.next := nil;
    end;
    close(mfile);
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

procedure hideC(c: character);
begin
    GotoXY(c.x, c.y);
    write('.');
end;

procedure moveC(var c: character);
var
    ch: char;
begin
    hideC(c);
    ch := ReadKey;
    case ch of
    'w': c.y -= 1;
    'a': c.x -= 1;
    's': c.y += 1;
    'd': c.x += 1;
    #27: halt;
    end;
    showC(c);
end;
{ /Character }

procedure init(var m: pmap; var c: character);
begin
    parseM(m);
    c.s := '@';
    c.x := 35;
    c.y := 6;
end;

var
    m: pmap;
    c: character;
begin
    clrscr;
    init(m, c);
    showM(m);
    while true do
    begin
        if KeyPressed then
            moveC(c);
        delay(50);
    end;
end.
