%{
Creates video from .jpg files within the figs file. Requires that files are
sorted alphabetically - else need to sort list of file names. 

Uses MATLAB's VideoWriter. For documentation see: 
https://www.mathworks.com/help/matlab/ref/videowriter.html
%}

v = VideoWriter('simple_sim_tesselation', 'MPEG-4');  % saves as mp4
v.FrameRate = 3;
open(v);

fileList = dir('*.jpg');
files = strings(length(fileList));
for ii = 1:length(fileList)
    files(ii) = fileList(ii).name;
    frame = imread(files(ii));
    writeVideo(v,frame)
end
close(v);