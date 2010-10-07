require 'digest/sha1'

module Similus
  class << self 
    def add_activity(a, action, b)
      # Find or create objects
      a = add_object(a)
      b = add_object(b)

      # Find or create action
      action = add_action({:name => action})

      # Create activities (both sides)
      create_activities(a, action, b)
      create_activities(b, action, a)
    end

    def similar_to(src, options={}, objects=nil)
      sopt = {:source => :all, :load_objects => true}.update(options)
      src = add_object(src)

      objects ||= load_activity(src, options)

      similar_objects = objects.inject(empty_hash) do |result, id|
        redis.smembers("activity:#{id}").each { |similar| result[similar] += 1 }
        result
      end

      similar_objects.delete(src[:obj_id])      # delete object itself form list
      similar_objects.reject! { |k,v| v == 1 }   # remove similars just by one

      if sopt[:load_objects] 
        load_objects(similar_objects.sort { |x,y| y[1] <=> x[1] })
      else
        similar_objects
      end
    end

    def recommended_for(src, options={}, &block)
      default_options = { :load_objects => true, :max_similar => 10,
                          :limit => 10, :offset => 0, :method => :similarity,
                          :source => :all, :target => :all }

      ropt = default_options.update(options)
      sopt = options.merge(:load_objects => false)
      maxs = ropt.delete(:max_similar)

      # Find objects for user
      src_act = load_activity(src, sopt)

      # Get similar objects, sort and get first N elements
      src_sim = similar_to(src, sopt, src_act).sort {|x,y| y[1] <=> x[1]}[0..maxs]

      # Get recommended score of similar objects's activity
      result = src_sim.inject(empty_hash) do |res, sim|
        dst_act = redis.smembers("activity:#{sim[0]}")
        rscore(ropt[:method], res, dst_act, src_act, sim[1], sim[0], &block)
      end

      # Remove already seen, sort and apply limit/offset
      result.reject! { |key,value| src_act.include?(key) }
      result = result.sort { |x,y| y[1] <=> x[1] }[ropt[:offset],ropt[:limit]]

      # Load original objects
      ropt[:load_objects] ? load_objects(result) : result
    end

    private

    def add_class(obj)
      obj = object_to_hash(obj)
      obj[:class_id] = cached_value("class:#{obj[:class]}") do
        safe_create("class", obj[:class])
      end
      obj
    end

    def add_object(obj)
      obj = object_to_hash(obj)
      # Find or create class
      add_class(obj) unless obj[:class_id] 

      # Find or create object
      obj[:obj_id] = cached_value("object:#{obj[:class]}:#{obj[:id]}") do
        safe_create('object', "#{obj[:class]}:#{obj[:id]}") do |id|
          redis.hmset("object:#{id}", :id, obj[:id], :class_id, obj[:class_id])
          redis.sadd("class:#{obj[:class_id]}:objects", id)
        end
      end
      obj
    end

    def add_action(action)
      action[:action_id] = cached_value("action:#{action[:name]}") do
        safe_create("action", action[:name])
      end
      action
    end

    def create_activities(src, action, dst)
      keys = [ activity_key(src[:obj_id]),
               activity_key(src[:obj_id], action[:action_id]),
               activity_key(src[:obj_id], action[:action_id], dst[:class_id]),
               activity_key(src[:obj_id], nil, dst[:class_id])]

      keys.each do |key|
        redis.sadd "#{key}",   dst[:obj_id]                 # Set
        redis.zadd "#{key}:s", Time.now.to_i, dst[:obj_id]  # Sorted List
      end
    end

    def activity_key(obj_id, action_id=nil, class_id=nil)
      str = "activity:#{obj_id}"
      str << ":a:#{action_id}" if action_id
      str << ":c:#{class_id}" if class_id
      str
    end

    def load_activity(src, options)
      aopt = { :source => :all,
               :max_activity_objects => 20,
             }.update(options)

      last = aopt.delete(:max_activity_objects)

      # Assign object and class ids
      src = add_object(src)

      # Retrieve last activity for obj
      act_key = activity_key(src[:obj_id])
      last ? redis.zrevrange("#{act_key}:s", 0, last-1) : redis.smembers(act_key)
    end

    # data_with_score is hash {key => score} or array [[key,score]]
    def load_objects(data_with_score)
      data_with_score = data_with_score.to_a if data_with_score.is_a?(Hash)
      data_with_score.map do |item|
        obj = redis.hgetall "object:#{item[0]}"
        { :score             => item[1],
          :id                => obj["id"],
          :class             => redis.get("class:#{obj["class_id"]}")
        }
      end
    end

    def object_to_hash(obj)
      case obj.class.to_s
      when "Array"
        {:class => obj[0], :id => obj[1]}
      when "Hash"
        obj
      else
        if obj.respond_to?(:id)
          {:class => obj.class.to_s, :id => obj.id}
        end
      end
    end

    def empty_hash(default=0.0)
      hash = Hash.new
      hash.default = default
      hash
    end

    def rscore(method, res, dst_act, src_act, src_sim_score, src_oid, &block)
      if block_given?
        params = [res, dst_act, src_act, src_sim_score, src_oid]
        block.call(*(params[0..block.arity]))
      else
        case method
        when :similarity
          dst_act.each do |dst_oid|
            res[dst_oid] += src_sim_score
          end
        when :jaccard
          puts "Doing jaccard"
          jf = jaccard_factor(src_act, dst_act)
          dst_act.each do |dst_oid|
            res[dst_oid] += 1000.0 * jf
          end
        when :jaccard_similarity
          jf = jaccard_factor(src_act, dst_act)
          dst_act.each do |dst_oid|
            res[dst_oid] += src_sim_score * jf
          end
        end
      end
      res
    end

    def jaccard_factor(src,dst)
      (src & dst).size.to_f / (src | dst).size.to_f
    end

    # Class level cache for objects
    def cache
      @cache ||= {}
    end

    def cached_value(key)
      cache[key] ||= yield
    end

    def safe_create(base, value)
      hash = Digest::SHA1.hexdigest(value.to_s)
      hkey = "#{base}:#{hash}:id"
      id   = redis.get(hkey)

      unless id
        id = redis.incr("next.#{base}.id").to_s(36) # use base 36 for ids to save space
        unless redis.setnx(hkey, id)
          id = redis.get(hkey)  # hash key created in between - revert to original value
        else
          block_given? ? yield(id) : redis.setnx("#{base}:#{id}", value)
        end
      end
      id
    end
  end # class << self 
end