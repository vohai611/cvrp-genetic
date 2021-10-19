#include <Rcpp.h>
using namespace Rcpp;

// This is a simple example of exporting a C++ function to R. You can
// source this function into an R session using the Rcpp::sourceCpp 
// function (or via the Source button on the editor toolbar). Learn
// more about Rcpp at:
//
//   http://www.rcpp.org/
//   http://adv-r.had.co.nz/Rcpp.html
//   http://gallery.rcpp.org/
//

// [[Rcpp::export]]
NumericVector gen_routeC(NumericVector x, int capacity, NumericVector demand) {

// algorithm
  int cur_cap  = capacity;
  int n = x.size();
  NumericVector path(n+20);
  path[0] = 1;
  int count = 1;
  
  for(int i = 0; i < n; i++) {
    if( cur_cap < demand[x[i] - 1]) {
      
      path[count + i] = 1;
      count++;
      path[count + i] = x[i];
      cur_cap = capacity - demand[x[i] -1];
    } else {
      path[count + i ]  = x[i];
      cur_cap = cur_cap - demand[x[i] -1];
    }
    
  }
  path.erase((count + n), n+20);
  path.push_back(1);
  return path;
}


// You can include R code blocks in C++ files processed with sourceCpp
// (useful for testing and development). The R code will be automatically 
// run after the compilation.
//


