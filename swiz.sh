# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see
# <https://www.gnu.org/licenses/>.



# for each [i:j] pair, copy from i to j
#
# the elements which haven't been explicitly moved will orderly occupy
# the remaining available slots.

# Examples
# swz 1:2,2:1 grep a b c e f foo*
# =>
# grep b a c e f foo*
#
#
# swz 6:1 echo a b c e f foo*
# =>
# echo foo* a b c e f
#
#
# swz 1:-1,-1:1,2:-2,-2:2 grep a b c e f foo*
# =>
# grep foo* f c e b a
#

# https://stackoverflow.com/questions/1527049/how-can-i-join-elements-of-a-bash-array-into-a-delimited-string
function join_by {
    local d=${1-} f=${2-}
    if shift 2; then
        printf %s "$f" "${@/#/$d}"
    fi
}

# if negative index, turn into positive
function neg_to_pos {
    i=$1
    sign=${i:0:1}

    if [ $sign = "-" ]
    then
        abs=${i:1}
        echo $((commandLength - abs))
    else
        echo $i
    fi
}

swz() {
    args=("$@")

    IFS=' ' read -r -a command <<< "${args[@]:1}"
    commandLength=${#command[@]}

    sources=()
    destinations=()
    result=()

    # split first argument into pairs
    IFS=',' read -r -a pairs <<< "$1"

    for i in ${!pairs[@]}; do
        IFS=':' read -r -a pair <<< ${pairs[$i]}

        source=$(neg_to_pos ${pair[0]})
        sources+=( $source )

        destination=$(neg_to_pos ${pair[1]})
        destinations+=( $destination )
    done

    # insert into result
    for i in ${!sources[@]}; do
        result[${destinations[$i]}]=${command[${sources[$i]}]}
    done

    # sort sources in descending order
    sortedSources=($(IFS=$'\n' sort -r <<<"${sources[*]}"))

    # loop over sorted sources and remove each of them from command
    for i in ${!sortedSources[@]}; do
        del_el=${sortedSources[$i]}
        command=( "${command[@]:0:$del_el}" "${command[@]:$((del_el+1))}")
    done

    # fill result with elements which haven't been explicitly moved
    j=0
    for i in ${!command[@]}; do
        if [ -z ${result[$j]} ]
        then
            result[$j]=${command[$i]}
            j=$((j+1))
        else
            while [[ -n ${result[$j]} && j -le commandLength ]]; do
                j=$((j+1))
            done
            result[$j]=${command[$i]}
        fi
    done

    to_exec=$(join_by ' ' "${result[@]}")

    $to_exec
}
