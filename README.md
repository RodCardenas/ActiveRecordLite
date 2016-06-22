# ActiveRecordLite
ActiveRecordLite is a personal project in which I built a stripped down version of ActiveRecord. The goal was to better grasp how ActiveRecord translates associations and queries into SQL.

Try it out:
-----
1. Clone me
2. Run ``rake db:create``
3. ``$ ruby demo.rb``
4. Open ``demo.rb`` and break all the things

[![Screenshot](/doc/screenshot.png)](//github.com/rodcardenas/code/)


Application:
------
```ruby
require_relative 'lib/active_record_lite'

# open database connection
# run rake db:create to auto-generate a seeded db/cats.sqlite3
DBConnection.open('db/cats.sqlite3')
```

Next, define a model:
```ruby
class Person < SQLObject
  my_attr_accessor :id, :first_name, :last_name, :house_id

  has_many :cats, foreign_key: :owner_id
  belongs_to :house
end
```

Through the use of ``my_attr_accessor``, the code allows us to define numerous variables at once:
```ruby
person = Person.new(first_name: 'Rod', last_name: 'Cardenas', house_id: 1)
```

ActiveRecordLite is as opinionated as ActiveRecord, if not more. For example, the ``foreign_key`` for ``has_many :cats`` would have been chosen to be ``:person_id`` and thus why we had to specify it as ``:owner_id``

To this end, the ``belongs_to`` and ``has_many`` associations accept overrides for ``:class_name``, ``:foreign_key``, and `:primary_key`:

```ruby
has_many :cats,
  foreign_key: :owner_id,
  class_name: 'Cat',
  primary_key: :id
```

In this example, the table name ``"persons"`` will be inferred by the code by taking the model's name and pluralizing it. To override this default assignment, call ``set_table_name "new_name"``:
```ruby
# define house model
class House < SQLObject
  set_table_name 'houses'
  my_attr_accessor :id, :address

  has_many :persons
end
```

Last, there is support for ``has_one_through``:
```ruby
class Cat < SQLObject
  set_table_name 'cats'
  my_attr_accessor :id, :name, :owner_id

  belongs_to :person, foreign_key: :owner_id
  has_one_through :house, :person, :house
end
```
