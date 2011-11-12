#ifndef TILEREPO_H
#define TILEREPO_H

#include "Tile.h"
#include "datastructs.h"

class TileRepo {
    int tiles[CHARNUM];
    int _numTiles;
public:
    TileRepo ();
    TileRepo (std::string str);
    bool hasTile (int i) const;
    Tile takeTile (int i);
    void takeTile (int i, int amt);
    void putTile (Tile t);
    void putTile (int i);
    void putTile (Tile t, int num);
    int numTiles () const;
    int numOf (int i) const; ///< number of tiles of letter-index i
    void empty ();
	friend std::string txtDisplay (const TileRepo&);
};

#endif // TILEREPO_H
