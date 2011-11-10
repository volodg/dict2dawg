#include "Dict.h"
#import "Card.h"

using std::string;
using std::vector;

bool Dict::load (string fname) {
    FILE *fp;
    uint nsize;
    if ((fp = fopen(fname.c_str(), "rb")) == 0) {
        return false;
    }
    if (fread(&nsize, sizeof(uint), 1, fp) != 1) {
        fclose(fp);
        return false;
    }
	//NSLog(@"nsize : %i",nsize);
    nodes.resize(nsize);
    for (uint i=0; i<nsize; i++) {
        nodes[i].unserialize(fp);
    }
    fclose(fp);
    return true;
}

bool Dict::contains (const string str) {
    int np = 0;
    for (uint i=0; i<str.size(); i++) {
        if ((np = nodes[np][toupper(str[i])-65]) == 0)
            return false;
    }
    if (nodes[np].isTerm) return true;
    else return false;
}

void Dict::setGrid(GameGrid * Grid)
{
	grid = Grid;
}

vector<string> Dict::findWords (TileRepo tiles) {
    string tmp;
    vector<string> res;
	findWordsRec (tiles, tmp, res, 0);
	/*CCLOG(@"count : %i",res.size());
	std::vector<string>::iterator pos;
    for(pos = res.begin(); pos != res.end(); ++pos) {
		string s = *pos;
		NSMutableString * ms = [NSMutableString string];
		for (uint i=0; i<s.size(); i++) 
			[ms appendFormat:@"%c",s[i]];
		CCLOG(@"%@",ms);
	}*/
    return res;
}

void Dict::findWordsRec (TileRepo &tiles, string &str, vector<string> &res, int np) {
    if (nodes[np].isTerm) {
        res.push_back(str);
    }
    for (int i=0; i<ALPHANUM; i++) {
        if (nodes[np][i] != 0) {
            if (tiles.hasTile(i)) {
				//CCLOG(@"hastile:%i",i);
                tiles.takeTile(i);
                str.push_back(i+65);
                findWordsRec(tiles, str, res, nodes[np][i]);
                str.erase(str.size()-1);
                tiles.putTile(Tile(i+97));
            } else if (tiles.hasTile(BLANK)) {
				//CCLOG(@"hastile: blank");
                tiles.takeTile(BLANK);
                str.push_back(i+65);
                findWordsRec(tiles, str, res, nodes[np][i]);
                str.erase(str.size()-1);
                tiles.putTile(Tile('?'));
            }
        }
    }
}

Constraint Dict::findConstraint (const string str) {
    Constraint cons;
    findConstraintRec (str, cons, 0, 0);
    return cons;
}

bool Dict::findConstraintRec (const string &str, Constraint &cons, int np, uint pos) {
    if (pos == str.size()) {
        if (nodes[np].isTerm) return true;
        else return false;
    }
    if (isalpha(str[pos]) && ((np = nodes[np][toindex(str[pos])]) != 0)) {
        return findConstraintRec(str, cons, np, pos+1);
    }
    else if (str[pos] == '?') {
        uint nsize = nodes[np].size();
        for (uint i=0; i<nsize; ++i) {
            const Edge next = nodes[np].at(i);
            if (findConstraintRec(str, cons, next.ptr, pos+1)) {
                cons.addLetter(next.val);
            }
        }
    }
    return false;
}

void Dict::findMovesRec (TileRepo &tiles, const int coord[2], int ori, int minLen, string &str, vector<MoveInfo> &res,
				   int depth, int np, int usedTiles) 
{
	int p[2] = {coord[0]+(ori^1)*depth, coord[1]+ori*depth};
	bool flag = (ori==HORIZONTAL && p[ori] == GRID_WIDTH) || (ori==VERTICAL && p[ori] == GRID_HEIGHT);
	if (nodes[np].isTerm && depth >= minLen && 
		(flag || ![grid hasCardAtX:p[1] andY:p[0]]) &&
		usedTiles > 0) 
	{
		//CCLOG(@"FIND RES");
		res.push_back(MoveInfo(coord[1],coord[0] , ori, str));
	}
	if (flag) return;
	if ([grid hasCardAtX:p[1] andY:p[0]]) 
	{
		char c = [grid getCardAtX:p[1] andY:p[0]].letter;
		if (nodes[np][toindex(c)] != 0) 
		{
			str.push_back(c);
			findMovesRec (tiles, coord, ori, minLen, str, res, depth+1, nodes[np][toindex(c)], usedTiles);
			str.erase(str.size()-1);
		}
		return;
	}
	uint nsize = nodes[np].size();
	for (uint i=0; i < nsize; ++i) 
	{
		const Edge next = nodes[np].at(i);
		if ([grid hasCardXLetter:next.val atX:coord[1]+ori*depth andY:coord[0]+(ori^1)*depth andOri:ori]) {
			//CCLOG(@"hasCardXLetter");
			int a;
			if (tiles.hasTile(next.val)) a = next.val+97;
			else if (tiles.hasTile(BLANK)) a = next.val+65;
			else continue;
			tiles.takeTile(toindex2(a));
			str.push_back(a);
			findMovesRec (tiles, coord, ori, minLen, str, res, depth+1, next.ptr, usedTiles+1);
			str.erase(str.size()-1);
			tiles.putTile(Tile(a));
		}
	}
}

void Dict::findMoves (TileRepo tiles, const int coord[2], int ori, int minLen, vector<MoveInfo> &res) {
	//CCLOG(@"Dict::findMoves (%i,%i) %i minL :%i",coord[1],coord[0],ori,minLen);
	string str;
	findMovesRec (tiles, coord, ori, minLen, str, res);
}

void Edge::unserialize (FILE *fp) {
    uint tmp = 0;
    if (fread(&tmp, 3, 1, fp) != 1) 
	{
//		CCLOG(@"Edge::serialize: write error.");
      NSLog( @"Edge::serialize: write error." );
		return;
	}
    val = tmp >> 17;
    ptr = tmp & 0x1FFFF;
}

void eachEdge( const Edge& edge_ )
{
   NSLog( @"val: %d", edge_.val );
}

void Node::unserialize (FILE *fp) {
    listSize = 0;
    if (fread(&listSize, 1, 1, fp) != 1)
	{
//		CCLOG(@"Node::serialize: read error.");
      NSLog( @"Node::serialize: read error." );
		return;
	}
	//NSLog(@"listSize : %i",listSize);
	edges.resize(listSize);
    for (uint i=0; i<listSize; ++i) 
        edges[i].unserialize(fp);

//   edges.each
//   std::for_each( edges.begin(), edges.end(), eachEdge );
//   NSMutableArray* array_ = [ NSMutableArray arrayWithCapacity: edges.size() ];
   std::string str_ = std::string();
   for ( NSUInteger index_ = 0; index_ < edges.size(); ++index_ )
   {
      str_.push_back( edges[index_].val + 65 );
   }

   //str_.c_str()
//   if ( str_.length() > 6 )

   //NSLog( @"Node::serialize: isTerm read error." );

    if (fread(&isTerm, sizeof(isTerm), 1, fp) != 1)
	{
//		CCLOG(@"Node::serialize: isTerm read error.");
      NSLog( @"Node::serialize: isTerm read error." );
		return;
	}

   if ( isTerm )
      NSLog( @"Node: %@ %@", [ [ NSString alloc ] initWithBytes: str_.c_str() length: str_.length() encoding: NSASCIIStringEncoding ]
            , isTerm ? @"+":@"-" );
}
