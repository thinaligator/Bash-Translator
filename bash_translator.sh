#!/bin/bash


ifNumber(){
    l='^[+-]?[0-9]+$'
    if  [[ $1 =~ $l ]]
    then
        return 0
    else
        return 1
    fi
}

whatSign(){
    if [[ $1 == "-gt" ]]; then echo ">";
    elif [[ $1 == "-lt" ]]; then echo "<";
    elif [[ $1 == "-eq" ]]; then echo "==";
    elif [[ $1 == "-ne" ]]; then echo "!=";
    elif [[ $1 == "-ge" ]]; then echo ">=";
    elif [[ $1 == "-le" ]]; then echo "<=";
    elif [[ $1 == "-a" ]]; then echo "&&";
    elif [[ $1 == "-o" ]]; then echo "||";
    fi
}

input=$1
output=$2

>$output 

echo "#include <stdio.h>" >> $output
echo "int main() {" >> $output


while read line
do
    echo $line

    # echo -> printf()
    if [[ $line == "echo"* ]]
    then
        singleRow=`echo $line | awk -F "echo " '{print $NF}'`
        if [[ ${singleRow:0:1} == "$" ]]
        then
            singleRow=${singleRow:1}
            echo "printf("\%\s", $singleRow);" >> $output
        elif ifNumber $singleRow
        then
            echo "printf("\%\d", $singleRow);" >> $output
        else
            echo "printf("\%\s", $singleRow);" >> $output
            
        fi
    fi

    # =
    if [[ $line == *"="* ]] && [[ $line != *"expr"* ]]
    then
        singleRow=`echo $line | awk -F "=" '{print $1}'`
        tempRow=`echo $line | awk -F "=" '{print $NF}'`

        if ifNumber $tempRow 
        then
            singleRow="int $singleRow"

        elif [[ ${tempRow:0:1} == "$" ]]
        then
            tempRow=${tempRow:1}

        else
            singleRow="char $singleRow[]"
        fi

        echo "$singleRow = $tempRow;" >> $output
  
    fi

    # if
    if [[ $line == "if"* ]]
    then
        IFS=' ' read -a rowPart <<< "$line"
        singleRow=${rowPart[2]:1}
        if [[ $singleRow == "$" ]]
        then
            singleRow=${singleRow:1}
        fi

        sign=${rowPart[3]}
        sign=`whatSign $sign`

        tempRow=${rowPart[4]}

        echo "if( $singleRow $sign $tempRow ) {" >> $output
    fi

    # elif
    if [[ $line == "elif"* ]]
        then
        echo "}" >> $output

        IFS=' ' read -a rowPart <<< "$line"
        singleRow=${rowPart[2]:1}
        if [[ $singleRow == "$" ]]
        then
            singleRow=${singleRow:1}
        fi

        sign=${rowPart[3]}
        sign=`whatSign $sign`

        tempRow=${rowPart[4]}

        echo "else if( $single $sign $tempRow ) {" >> $output
    fi

    # else
    if [[ $line == "else" ]]
    then
        echo "}" >> $output
        echo "else {" >> $output
    fi

    # fi
    if [[ $line == "fi" ]]
    then
        echo "}" >> $output
    fi

    # expr
    if [[ $line == *"\`expr"* ]]
    then
        singleRow=`echo $line | awk -F "expr" '{print $1}'`
        singleRow=${singleRow:0:1}

        tempRow=`echo $line | awk -F "expr" '{print $2}'`
        IFS=' ' read -a rowPart <<< "$tempRow"

        str=""
        for v in "${rowPart[@]}"
        do
            if [[ ${v:0:1} == "$" ]]
            then
                v=${v:1}
            fi
            
            str+=" $v"
        done
        
        echo "$singleRow = ${str:0:-1};" >> $output
        

    fi

    # while
    if [[ $line == "while"* ]]
    then
        IFS=' ' read -a rowPart <<<"$line" 
        singleRow=${rowPart[2]:1}
        if [[ $singleRow == "$" ]]
        then
            singleRow=${singleRow:1}
        fi

        sign=${rowPart[3]}
        sign=`whatSign $sign`

        tempRow=${rowPart[4]}

        echo "while( $singleRow $sign $tempRow ) {" >>$output
    fi

    # done
    if [[ $line == "done" ]]
    then
        echo "}" >> $output
        
    fi

    # for
    if [[ $line == "for"* ]]
    then
        IFS=' ' read -a rowPart <<<"$line" 
        singleRow=${rowPart[1]}
        if [[ $singleRow == "$" ]]
        then
            singleRow=${singleRow}
        fi

        tempRow=`echo $line | awk -F "{" '{print $NF}'`
        tempRow=${tempRow:0:-1}
        IFS='..' read -a arr2 <<<"$tempRow" #for loop parameters

        firstArg=${arr2[0]}
        secondArg=${arr2[2]}
        step=${arr2[4]}


        if [ $step ] #if there is a step parameter
        then
            if [[ $firstArg < $secondArg ]]
            then
                #incrementation
                echo "for( int $singleRow=$firstArg; $<=$secondArg; $singleRow+=$step ) {" >>$output
            else
                #decrementation
                echo "for( int $singleRow=$firstArg; $singleRow>=$secondArg; $singleRow-=$step ) {" >>$output
            fi


        else
            if [[ $firstArg < $secondArg ]]
            then
                #incrementation
                echo "for( int $singleRow=$firstArg; $singleRow<=$secondArg; $singleRow++ ) {" >>$output
            else
                #decrementation
                echo "for( int $singleRow=$firstArg; $singleRow>=$secondArg; $singleRow-- ) {" >>$output
            fi
        fi

    fi

    



done < $input

echo "}" >> $2 
