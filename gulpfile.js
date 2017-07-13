var gulp = require('gulp');
var concat = require('gulp-concat');
 
gulp.task('compile', function() {
  return gulp.src(['./src/globals.lua', './src/collectibles/**/*', './src/enemies/**/*'])
    .pipe(concat({ path: 'main.lua', stat: { mode: 0666 }}))
    .pipe(gulp.dest('.'));
});

gulp.task('watch', function () {
   gulp.watch('./src/**/*', ['compile']);
});