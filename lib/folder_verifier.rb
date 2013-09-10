require 'thor'
require 'fileutils'
require 'find'
require 'pathname'
require 'table_print'

module FolderVerifier
  class CLI < Thor
		desc "verify PATH", "Verifies folder at given path."
	  method_option :verbose, :aliases => "-v", :desc => "Be verbose"
	  def verify(path)
	    FolderVerifier::verify(path, options)
	   
	  end
	  
		desc "clone SOURCE", "Clones folder at given source, to given dest. Looks at number of images in per folder in source and creates a .x filename (e.g. .12) in each folder representing the intended number of images for each folder."
	  method_option :verbose, :aliases => "-v", :desc => "Be verbose"
	  method_option :examples, :desc => "Create example images in each folder."
	  method_option :include_thumbs, :desc => "Includes thumbs folder."
	  def clone(source, dest)

	    FolderVerifier::clone_folder_structure(source, dest, options)
	   
	  end
	  
		desc "fill PATH", "Verifies folder at given path."
	  method_option :verbose, :aliases => "-v", :desc => "Be verbose"
	  def fill(path)
	    FolderVerifier::fill(path, options)
	   
	  end
	  
	  
		desc "print PATH", "Prints a representation of folder directory."
	  method_option :verbose, :aliases => "-v", :desc => "Be verbose"
	  def print(path)
	  
	    FolderVerifier::print_tree(path)
	  end
	  
  end

  class FolderVerifier
    
		def self.is_numeric?(s)
		  begin
		    Float(s)
		  rescue
		    false # not numeric
		  else
		    true # numeric
		  end
		end
		
		def self.is_image?(filename)
			allowed_file_types = [".png", ".jpg", ".jpeg", ".gif"]
			file_type_allowed = false
			
			for allowed_file_type in allowed_file_types
				if filename.include?(allowed_file_type)
					file_type_allowed = true
					break
				end
			end
			return file_type_allowed
		end
		
    
    def self.verify(path, options)
      response = ""
      
      puts "--FILE--"
      puts Dir.pwd
      
      error_array = []
      
      Find.find(path) do |node|
        
        pn = Pathname.new(node)
        # if is folder, and non-numeric, Clone.
        if pn.basename.to_s[0] == "." and self.is_numeric?(pn.basename.to_s[1..-1])
          number = pn.basename.to_s[1..-1].to_i
          parent_folder = node.split(File::SEPARATOR)[0..-2].join(File::SEPARATOR)
          
          count = 0
          Dir.foreach(parent_folder) do |item|
            if self.is_image?(item)
              count += 1
            end
          end
          
          if count != number

            output = "ERROR: incorrect number of images in %s.\nThere should be: %d. \nThere are only: %d \n\n" % [parent_folder.gsub(path, ""), number, count]
            response += output    
            
            error_hash = {}
            error_hash['path'] = parent_folder.gsub(path, "")    
            error_hash['Number of Images'] = count
            error_hash['Expected Number of Images'] = number
            error_array.push(error_hash)
            
            puts output
            
          end
          
        end
      end
      
      tp.set :max_width, 100
      if response == ""
        response = "No errors found"
      else
        printer = TablePrint::Printer.new(error_array, {})
        puts printer.table_print unless error_array.is_a? Class
        
        return printer.table_print unless error_array.is_a? Class
      end
      
      return response
    end
		
		
		# Clones folder structure
    def self.clone_folder_structure(source, dest, options)
      
      Find.find(source) do |node|
        
        pn = Pathname.new(node)
        # if is folder, and non-numeric, Clone.
        
        if File.directory? (node) and not self.is_numeric?(pn.basename.to_s) or pn.basename.to_s.length == 1
          
          if pn.basename.to_s == "thumbs" and not options[:include_thumbs]
            next
          end
          
          folders = node.split(File::SEPARATOR)
          new_path = File.join(dest, folders[1..-1].join(File::SEPARATOR))
          
          FileUtils.mkdir_p new_path
          
          count = 0
          example_image = nil
          new_example_image = nil
    			Dir.foreach(node) do |item|
    			  next if item == '.' or item == '..' or item == '.DS_Store'
    			  if self.is_numeric?(Pathname.new(item).basename.to_s) and item.length != 1
    			    if Pathname.new(item).basename.to_s.to_i != 0
    			      count += 1
    			      
    			      if count == 1
      			      Dir.foreach(File.join(node, item)) do |image|
      			        if self.is_image?(image)
      			          new_example_image = File.join(new_path,image)
      			          example_image = File.join(node,item,image)
      			          break
      			        end
      			      end
    			      end
    			          			      
    			    end
    			  elsif item.length == 1

    			  else
    			    if self.is_image? (item)
			          example_image = File.join(node,item)
    			      count = 1
    			      break
    			    end
    			  end
    			end
    			
    			if count >= 1
      			number_specifier_path = File.join(new_path, "." + count.to_s)
            FileUtils.touch(number_specifier_path)
            
            if example_image and options[:examples]
              new_example_image = File.join(new_path, "%d of these.png" % count)
              FileUtils.cp(example_image, new_example_image)
            end
          end
        end
      end				
    end
    
    
    
		# Clones folder structure
    def self.fill(path, options)
      
      Find.find(path) do |node|
        
        pn = Pathname.new(node)
        
        
        if File.directory?(node)
          add_dot_file = true
          puts "path: %s" % node
          Dir.foreach(node) do |item|
            if item == "." or item == ".." or item == ".DS_Store"
              next
            end
            if item.to_s[0] == "." and self.is_numeric?(item.to_s[1..-1])
              add_dot_file = false
              puts "already a dot file"
              break
            end
            
            if File.directory?(File.join(node, item))
              add_dot_file = false
              puts "contains dir: %s" % item
              break
            end
          end
          
          
          if add_dot_file
            puts "add dot"
            FileUtils.touch(File.join(node, ".1"))
          end
          
        end
        
      end
    end
    
    
      
    def self.print_tree(dir = ".", nesting = 0) 
      Dir.foreach(dir) do |entry| 
        next if entry =~ /^\.{1,2}/   # Ignore ".", "..", or hidden files 
        
#         if File.directory?(entry)
#           puts "|   " * nesting + "|-- #{entry}" 
#         end
        
        if File.stat(d = "#{dir}#{File::SEPARATOR}#{entry}").directory? 
          if not self.is_numeric?(entry) or entry.length == 1
            count = 0
            Dir.foreach(d) do |dot_file|
              if dot_file.to_s[0] == "." and self.is_numeric?(dot_file.to_s[1..-1])
                count = dot_file.to_s[1..-1].to_i
                break
              end
            end
            
            puts "|   " * nesting + "|-- #{entry}" + (count == 0 ? "" : " (x %d)" % count)
          end
          print_tree(d, nesting + 1) 
        end 
      end 
    end 
    
  end  
end


# @todo Move somewhere else
class Dir 
  def Dir.print_tree(dir = ".", nesting = 0) 
    Dir.foreach(dir) do |entry| 
      next if entry =~ /^\.{1,2}/   # Ignore ".", "..", or hidden files 
      puts "|   " * nesting + "|-- #{entry}" 
      if File.stat(d = "#{dir}#{File::SEPARATOR}#{entry}").directory? 
        print_tree(d, nesting + 1) 
      end 
    end 
  end 
end 

