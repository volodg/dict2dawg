#include "TileRepo.h"
#include <cstdlib>
#include <cmath>

using namespace std;

TileRepo::TileRepo () : _numTiles(0) {
    for (int i=0; i<CHARNUM; i++)
        tiles[i] = 0;
}
TileRepo::TileRepo (std::string str) : _numTiles(0) {
    for (int i=0; i<CHARNUM; i++)
        tiles[i] = 0;
    for (uint i=0; i<str.size(); i++) {
        if (isalpha(str[i]) || str[i] == '?') {
            tiles[toindex2(str[i])]++;
            _numTiles++;
        }
        else
        {
			//CCLOG(@"TileRepo::(string)");
        }
    }
}
bool TileRepo::hasTile (int i) const { ///< @param i The tile letter in INDEX format
    return tiles[i] > 0;
}
Tile TileRepo::takeTile (int i) { ///< @param i The tile letter in INDEX format
    --tiles[i];
    --_numTiles;
    if (i < ALPHANUM) return Tile(i+97);
    else if (i == BLANK) return Tile('?');
//    else CCLOG(@"TileRepo::takeTile()");
	return Tile(' ');
}
void TileRepo::takeTile (int i, int amt) { /// discards @param amt number of type @param i tiles
    tiles[i] -= amt;
    _numTiles -= amt;
}
void TileRepo::putTile (Tile t) { ///< @param t Uppercase and '?' letters will be interpreted as blanks
    ++tiles[toindex2(t.letter())];
    ++_numTiles;
}
void TileRepo::putTile (int i) {
    ++tiles[i];
    ++_numTiles;
}
void TileRepo::putTile (Tile t, int num) { ///< @param t Uppercase and '?' letters will be interpreted as blanks
    tiles[toindex2(t.letter())] += num;
    _numTiles += num;
}
int TileRepo::numTiles () const {
    return _numTiles;
}
int TileRepo::numOf (int i) const {
    return tiles[i];
}
void TileRepo::empty () {
    for (int i=0; i<CHARNUM; i++)
        tiles[i] = 0;
    _numTiles = 0;
}

string txtDisplay (const TileRepo& tileRepo) {
    string str;
    for (int i=0; i<CHARNUM; i++) {
        for (int j=0; j<tileRepo.numOf(i); j++) {
            if (i < ALPHANUM) str.push_back(i+97);
            else if (i == BLANK) str.push_back('?');
//            else CCLOG(@"TileRepo::display()");
        }
    }
    return str;
}