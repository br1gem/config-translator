#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

swift_command=(swift)
if [[ "$(uname -s)" == Darwin ]]; then
    swift_command=(xcrun swift)
fi

"${swift_command[@]}" build >&2
program=$("${swift_command[@]}" build --show-bin-path)/config-translator

test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT
input="$test_dir/input.cfg"
output="$test_dir/stdout"
errors="$test_dir/stderr"

check_json() {
    local file=$1 expected=$2 label=${3:-$1}

    if ! "$program" --input "$file" > "$output" 2> "$errors" ||
        [[ "$(cat "$output")" != "$expected" || -s "$errors" ]]; then
        printf 'FAIL: %s\nОжидалось: %s\n' "$label" "$expected" >&2
        cat "$output" "$errors" >&2
        exit 1
    fi

    printf 'OK: %s\n' "$label"
}

check_value() {
    printf '%s\n' "$2" > "$input"
    check_json "$input" "$3" "$1"
}

check_error() {
    local label=$1 expected=$2 status=0

    "$program" --input "$3" > "$output" 2> "$errors" || status=$?

    if [[ "$status" -ne 1 || -s "$output" ]] || ! grep -Fq "$expected" "$errors"; then
        printf 'FAIL: %s (код %s)\nОжидалось: %s\n' "$label" "$status" "$expected" >&2
        cat "$output" "$errors" >&2
        exit 1
    fi

    printf 'OK: %s\n' "$label"
}

check_invalid() {
    printf '%s\n' "$2" > "$input"
    check_error "$1" "$3" "$input"
}

check_json examples/game.cfg \
    '{"TITLE": "Clade", "PLAYER": {"SPEED": 3.5}, "LEVELS": ["Forest", "Cave"]}'
check_json examples/weather.cfg \
    '{"STATION": "North", "READINGS": [18.4, 19.1, 20.0], "SENSOR": {"ACCURACY": 0.5}}'
check_json examples/store.cfg \
    '{"ITEMS": [{"NAME": "Swift", "PRICE": 12.50}], "DISCOUNT": 0.15}'

check_value 'Пустые значения и ведущие нули' \
    'array("", array(), @{}, 000.25)' '["", [], {}, 0.25]'
check_value 'Константа с массивом' \
    $'const A = .5\nconst B = array(|A|)\n|B|' '[0.5]'

check_invalid 'Пропущена точка с запятой' '@{A = 1.0}' 'expected ";"'
check_invalid 'Строчное имя' '@{name = .5;}' 'Синтаксическая ошибка'
check_invalid 'Целое число' '123' 'Синтаксическая ошибка'
check_invalid 'Неизвестная константа' '|MISSING|' \
    'Константа «MISSING» ещё не объявлена.'
check_invalid 'Повтор константы' $'const A = .5\nconst A = .6\n|A|' \
    'Константа «A» уже объявлена.'
check_invalid 'Повтор ключа' '@{A = .5; A = .6;}' 'Ключ «A» повторяется в словаре.'
check_error 'Файл отсутствует' 'Не удалось прочитать файл' "$test_dir/missing.cfg"

printf 'Все проверки прошли.\n'