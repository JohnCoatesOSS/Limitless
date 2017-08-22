
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export SOURCE_ROOT=$DIR/dev
export BUILD_ROOT=$SOURCE_ROOT/build

# Get Latest OCLint

git clone https://github.com/johncoatesoss/oclint $SOURCE_ROOT

# Build Clang

cd $SOURCE_ROOT/oclint-scripts

./clang co
# Retrieve clang quietly
#echo "Checking out LLVM"
#svn co --quiet http://llvm.org/svn/llvm-project/llvm/tags/RELEASE_500/rc2 $SOURCE_ROOT/llvm
#echo "Checking out Clang"
#svn co --quiet http://llvm.org/svn/llvm-project/cfe/tags/RELEASE_500/rc2 $SOURCE_ROOT/llvm/tools/clang
#echo "Checking out compiler-rt"
#svn co --quiet http://llvm.org/svn/llvm-project/compiler-rt/tags/RELEASE_500/rc2 $SOURCE_ROOT/llvm/projects/compiler-rt

echo "Building Clang"
./clang build

# Compile oclint-core

mkdir -p $BUILD_ROOT/oclint-core
cd $BUILD_ROOT/oclint-core
cmake -G Xcode -D OCLINT_BUILD_TYPE=Release -D CMAKE_CXX_COMPILER=$BUILD_ROOT/llvm-install/bin/clang++ -D CMAKE_C_COMPILER=$BUILD_ROOT/llvm-install/bin/clang -D LLVM_ROOT=$BUILD_ROOT/llvm-install $SOURCE_ROOT/oclint-core
xcodebuild -target OCLintCore

# Compile oclint-metrics

mkdir -p $BUILD_ROOT/oclint-metrics
cd $BUILD_ROOT/oclint-metrics
cmake -G Xcode -D OCLINT_BUILD_TYPE=Release -D CMAKE_CXX_COMPILER=$BUILD_ROOT/llvm-install/bin/clang++ -D CMAKE_C_COMPILER=$BUILD_ROOT/llvm-install/bin/clang -D LLVM_ROOT=$BUILD_ROOT/llvm-install $SOURCE_ROOT/oclint-metrics
xcodebuild -target OCLintMetric


# Create oclint-rules project

mkdir -p $BUILD_ROOT/oclint-rules
cd $BUILD_ROOT/oclint-rules
cmake -G Xcode -D OCLINT_BUILD_TYPE=Release -D CMAKE_CXX_COMPILER=$BUILD_ROOT/llvm-install/bin/clang++ -D CMAKE_C_COMPILER=$BUILD_ROOT/llvm-install/bin/clang -D OCLINT_BUILD_DIR=$BUILD_ROOT/oclint-core -D OCLINT_SOURCE_DIR=$SOURCE_ROOT/oclint-core -D OCLINT_METRICS_SOURCE_DIR=$SOURCE_ROOT/oclint-metrics -D OCLINT_METRICS_BUILD_DIR=$BUILD_ROOT/oclint-metrics -D LLVM_ROOT=$BUILD_ROOT/llvm-install $SOURCE_ROOT/oclint-rules
