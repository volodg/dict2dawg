
#include <string>

using std::string;

class MoveInfo{
public:
	int x;
	int y;
	int ori;
	string str;

	MoveInfo();
	MoveInfo(int X, int Y, int Ori, string Str);
}; 
