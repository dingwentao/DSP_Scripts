function [my_modes,my_range_gates,socket_payload_size] = arena_xml_parse(filename)
%% Last updated by Zhe Jiang on April 11, adding socket_payload_size

%arena_xml_parse Parses a configuration XML file from an ARENA system
%   Outputs a horizontal array of modes that will be found in the .dat
%   files and the range gates associated with each in a separate matix.
%
%   Note that this currently only works for single-subchannel systems or
%   multi-subchannel systems that use the same modes.
%   Add parsing the payload buffer size
if ~ isfile(filename)
	fprintf('Cannot find the xml file %s',filename);
	exit;
end

xDoc = xmlread(filename);

% Cycle through all of the <digRx> elements, compiling a list of the ones
% that should be expected.
my_modes = [];
all_digRx = xDoc.getElementsByTagName('digRx');
for k = 0:all_digRx.getLength-1
  this_digRx = all_digRx.item(k);
  
  % Get the <modes> element.
  this_list = this_digRx.getElementsByTagName('modes');
  this_element = this_list.item(0);
  
  % Grab the mode and see if we have it already.
  this_modes = str2double(...
	strsplit(char(this_element.getFirstChild.getData),':'));
  
  if ~ismember(this_modes, my_modes)
    % The current mode does not exist in the set of found modes.
    my_modes = [my_modes this_modes];
  end
end
clear all_digrx this_digRx this_list this_element this_mode;

% Cycle through all of the <integrator> elements.
my_range_gates = zeros(2,size(my_modes,2));
all_integrator = xDoc.getElementsByTagName('integrator');
for k = 0:all_integrator.getLength-1
  this_integrator = all_integrator.item(k);
  
  % Get the <modes> and <rg> elements.
  this_list = this_integrator.getElementsByTagName('modes');
  this_modes_element = this_list.item(0);
  this_list = this_integrator.getElementsByTagName('rg');
  this_range_gates_element = this_list.item(0);
  
  % Fill in all range gates entries for each mode listed.
  this_mode = str2num(this_modes_element.getFirstChild.getData);
  this_range_gates = str2double( ...
    strsplit(char(this_range_gates_element.getFirstChild.getData),':'));
  % Cycle through all the modes in this set to set up the range gates.
  for k2 = 1:size(this_mode,2)
    % Find current mode's index in the my_modes array.
    index = find(my_modes==this_mode(k2));
    
    my_range_gates(1,index) = this_range_gates(1);
    my_range_gates(2,index) = this_range_gates(2);
  end
end


bufsize_elem = xDoc.getElementsByTagName('bufSize').item(0);
socket_payload_size = str2double(bufsize_elem.getFirstChild.getData);

end


