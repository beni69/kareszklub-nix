---
title: "Nix|NixOS"
author: Beni
lang: hu

controlsTutorial: 0
---

## Basics

### Linux, és programok

- Package: egy dolog amit letöltesz (és telepítesz), pl. egy program vagy egy betűtípus
- Minden disto-hoz van egy package gyűjtemény (repo), innen töltöd le a packageket
- \+ biztonság, kevesebb helyet foglal, egyszerű frissítések

### Mi az a Nix?

- **Nix package manager** *(cross-platform)*
- Nix language
- NixOS linux distro
- Nixpkgs package repository

## A Nix package manager

### "Pure functional"

```js
// impure
const list = []; // global state
function double_to_list(x) {
    list.push(x * 2); // side effect
}
```

. . .

```js
// pure
function double_to_list(list, x) {
    return [...list, x * 2];
}
```

---

- Minden package egy "pure function":
- Nincs side-effect ("sandboxing", elkülönítés)
- Same input => same output ("reproducible", avagy megismételhető)

---

![Filesystem Hierarchy Standard (FHS)](https://www.linuxfoundation.org/hubfs/Imported_Blog_Media/standard-unix-filesystem-hierarchy-1.png)

### /nix/store

- Minden package itt él
- `/nix/store/abcd123...-firefox-69.1/`
- Input hash + Name + Version

---

- "atomic" frissítések, avagy nem változtat semmit ha nem fut végig
- Egy program, több verzió
- Több felhasználó esetén szétválaszt, de nem duplikál
- Nincs "global state" -> minden program és a többi package amit használ el van különítve

## Nix language

### About

- Domain Specific Language
- Célja: programokhoz build scriptek, rendszer konfigurációk
- Pure functional
- Lazily evaluated

### Syntax

```nix
str = ''
multiline
string
'';

list = [ 1 [ 2 3 ] "4" ];

set = { a = 1; b = {x = true; y = false;}; c.x = true; };

hello = name: "hello ${name}";

add = a: b: a + b;

{ greeting = hello "Beni"; sum = add 1 2; path = ./foo; };
```

### Example

```c
// hello.c
void main() {
    printf("Hello world!\n");
}
```

. . .

```nix
# default.nix
{ stdenv }:

stdenv.mkDerivation {
  name = "hello";
  src = ./.;
  buildPhase = ''
    ${stdenv.cc}/bin/gcc hello.c -o hello
  '';
  installPhase = ''
    mkdir -p $out/bin
    cp hello $out/bin
  '';
}
```

### Remote source

```nix
# default.nix
{ stdenv, fetchFromGitHub }:

stdenv.mkDerivation rec {
  pname = "hello";
  version = "0.1.0";
  src = fetchFromGitHub {
    owner = "beni69";
    repo = "hello-c";
    rev = version;
    sha256 = "ABCDEFG0123456789...";
  };
  ...
}
```

### Shell environment

imperative:
```sh
nix-shell -p python3 -p gcc
```

. . .

declarative:
```nix
# shell.nix
{ pkgs ? import <nixpkgs> {} }:
pkgs.mkShell {
    nativeBuildInputs = [ pkgs.python3 pkgs.gcc ];
}
```

### Docker image

```nix
{ pkgs ? import <nixpkgs> { } }:

pkgs.dockerTools.buildImage {
  name = "hello-docker";
 version = "1.0.0";
  config = {
    Cmd = [ "${pkgs.hello}/bin/hello" ];
  };
}

```

## NixOS

### System management

**Imperatív** hagyományos

```sh
echo "beni-laptop" > /etc/hostname
ln -sf /usr/share/zoneinfo/Europe/Budapest /etc/localtime
apt install neovim
```

. . .

**Deklaratív** *(+ pure functional)* nix

```nix
networking.hostName = "beni-laptop";
time.timeZone = "Europe/Budapest";
environment.systemPackages = [ pkgs.neovim ];
```

### Oké, de miért?

- OS-szintű verziókezelés
- Könnyű *(újra)*telepítés
- Konfiguráció megosztása

### Example: install Docker

```sh
# https://docs.docker.com/engine/install/ubuntu/
```
```sh
sudo apt-get update
sudo apt-get install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release
sudo mkdir -m 0755 -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo chmod a+r /etc/apt/keyrings/docker.gpg
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

### NixOS

```nix
virtualisation.docker.enable = true;
```

### Nem csak PC-ken

Pl. szervereken is

- (sajnos a legtöbb cloud-on nem elérhető)
- Docker helyett NixOS modulok

. . .

```nix
services.thing = {
  enable = true;
  ...
};
```

## Nixpgs

### A legnagyobb package repo

[Top 3](https://repology.org/repositories/statistics/total):

>
- nixpkgs 22.11 ~80,000
- AUR ~70,000
- Ubuntu 23.04 ~35,000

### A nixpkgs filozófia

- Ha van egy program ami nincs a repo-ban, írj rá magad egy nix package-t
- Ha úgy gondolod, hogy másoknak is hasznos lehet, [küldj egy PR-t](https://github.com/NixOS/nixpkgs)

### Binary cache

- Normal package repo: binaries
- Nixpkgs: build scripts
- Nix binary cache: binaries

## Nix flakes

### Dependency management

- Nix expression (package vagy NixOS) dependency management
- Alapból a system nixpkgs verzió "impure global state"
- Minden inputot (nixpkgs, vagy másik nix library) meg kell adni

### Example flake

```nix
# flake.nix
{
  description = "A very basic flake";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs";

  outputs = { self, nixpkgs }: {
    packages.x86_64-linux.hello = nixpkgs.legacyPackages.x86_64-linux.hello;

    packages.x86_64-linux.default = nixpkgs.callPackage ./default.nix {};
  };
}
```

### Flake references

- Nix expression-ök könnyű használata
- `gitprovider:User/Repo/Rev`
- `path:/home/beni/flake`

. . .

demo:
```sh
nix run github:beni69/netbench
```


## Konklúzió

### Nix

Egy (nehés és bonyolult) pure functional build rendszer, amit ha egyszer megtanulsz,
akkor egyszerűvé válik a programjaid terjesztése Linuxon, Dockerben, és MacOS-en is.

### NixOS

A Nix build system megismételhetőségének köszönhetően egy verziókezelhető deklaratív rendszer.

A használatához Nix tudás segít, de nem feltétlen kötelező.
