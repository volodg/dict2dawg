#!/bin/bash

echo "======"

for dir in $(ls -1 -R); do   
if [ -d "$dir" ]; then
       svn propset svn:ignore "" "$PWD/$dir"
       svn propset svn:ignore "" "$PWD/$dir/$dir.xcodeproj"
fi
done

for dir in $(ls -1); do   
    if [ -d "$dir" ]; then
       echo "$PWD/$dir"
       echo "$PWD/$dir/$dir.xcodeproj"

       svn propset svn:ignore -F "$PWD/svnignore.txt" "$PWD/$dir"
       svn propset svn:ignore -F "$PWD/xcodeproj_ignore.txt" "$PWD/$dir/$dir.xcodeproj"

       echo "---"       
    fi 
done
echo "======"

