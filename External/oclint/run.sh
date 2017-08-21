DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR=$DIR/../../
cd $PROJECT_DIR
$DIR/bin/oclint-json-compilation-database -v -- -report-type xcode -R=$DIR/lib/oclint/customRules