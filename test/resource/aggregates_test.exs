defmodule Ash.Test.Resource.AggregatesTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias Ash.Resource.Aggregate

  defmodule Comment do
    @moduledoc false
    use Ash.Resource, data_layer: Ash.DataLayer.Ets

    attributes do
      uuid_primary_key :id
      attribute :post_id, :uuid
    end
  end

  defmacrop defposts(do: body) do
    quote do
      defmodule Post do
        @moduledoc false
        use Ash.Resource, data_layer: Ash.DataLayer.Ets

        attributes do
          uuid_primary_key :id
        end

        unquote(body)
      end
    end
  end

  describe "representation" do
    test "aggregates are persisted on the resource properly" do
      defposts do
        aggregates do
          count :count_of_comments, :comments
          count :another_count_but_private, :comments, private?: true
          sum :sum_of_comment_likes, :comments, :likes
        end

        relationships do
          has_many :comments, Comment, destination_attribute: :post_id
        end
      end

      assert [
               %Aggregate{
                 name: :count_of_comments,
                 kind: :count,
                 relationship_path: [:comments],
                 private?: false
               },
               %Aggregate{
                 name: :another_count_but_private,
                 kind: :count,
                 relationship_path: [:comments],
                 private?: true
               },
               %Ash.Resource.Aggregate{
                 field: :likes,
                 kind: :sum,
                 name: :sum_of_comment_likes,
                 private?: false,
                 relationship_path: [:comments]
               }
             ] = Ash.Resource.Info.aggregates(Post)

      assert [
               %Aggregate{name: :count_of_comments},
               %Aggregate{name: :sum_of_comment_likes}
             ] = Ash.Resource.Info.public_aggregates(Post)

      assert %Aggregate{name: :another_count_but_private} =
               Ash.Resource.Info.aggregate(Post, :another_count_but_private)

      assert nil == Ash.Resource.Info.public_aggregate(Post, :another_count_but_private)

      assert nil == Ash.Resource.Info.aggregate(Post, :totally_legit_aggregate)
    end

    test "Aggregate descriptions are allowed" do
      defposts do
        aggregates do
          count :count_of_comments, :comments, description: "require one of name/contents"
        end

        relationships do
          has_many :comments, Comment, destination_attribute: :post_id
        end
      end

      assert [
               %Ash.Resource.Aggregate{description: "require one of name/contents"}
             ] = Ash.Resource.Info.aggregates(Post)
    end
  end
end
