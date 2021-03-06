defmodule Brex.Operator.BuilderSpec do
  use ESpec, async: true

  alias Support.Operators

  describe "invalid Operator rules" do
    context "with no options" do
      let :invalid_rule do
        defmodule NoOptions do
          use Brex.Operator

          # Suppress an irrelevant not implemented warning
          Module.delete_attribute(__MODULE__, :behaviour)
        end
      end

      it "should raise a CompileError" do
        expect (&invalid_rule/0) |> to(raise_exception CompileError)
      end
    end

    context "with no aggregator but a clauses option" do
      let :invalid_rule do
        defmodule ClausesButNoAggregator do
          use Brex.Operator, clauses: :foo

          # Suppress an irrelevant not implemented warning
          Module.delete_attribute(__MODULE__, :behaviour)
        end
      end

      it "should raise a CompileError" do
        expect (&invalid_rule/0) |> to(raise_exception CompileError)
      end
    end

    context "with both options but a string as clauses value" do
      let :invalid_rule do
        defmodule InvalidClausesValue do
          use Brex.Operator, aggregator: &Enum.all?/1, clauses: "Can't use this"
        end
      end

      it "should raise a CompileError" do
        expected_message = "Invalid value for option `:clauses`: \"Can't use this\""

        expect (&invalid_rule/0) |> to(raise_exception ArgumentError, expected_message)
      end
    end
  end

  defmodule ValidOperatorRule do
    use ESpec, async: true, shared: true

    import Brex.Assertions.Rule

    alias Brex.Operator.Aggregatable

    let_overridable :rule_module
    let_overridable :aggregator
    let_overridable :clauses

    let_overridable rule: struct(rule_module(), %{clauses: clauses()})

    it "should be a rule" do
      expect rule() |> to(be_rule())
    end

    it "should contain the aggregator" do
      rule()
      |> Aggregatable.aggregator()
      |> should(eq aggregator())
    end

    it "should contain the clauses" do
      rule()
      |> Aggregatable.clauses()
      |> should(eq clauses())
    end

    it "a non empty list should satisfy the rule" do
      expect [1, 2, 3] |> to(satisfy_rule(rule()))
    end

    it "a empty list should not satisfy the rule" do
      expect [] |> to_not(satisfy_rule(rule()))
    end

    it "a non empty map should not satisfy the rule" do
      expect %{} |> to_not(satisfy_rule(rule()))
    end

    it "a string should not satisfy the rule" do
      expect "foobar" |> to_not(satisfy_rule(rule()))
    end
  end

  let clauses: [&is_list/1, &(length(&1) > 0)]

  operators = %{
    "a nested rule with both options" => Operators.BothOptions,
    "a nested rule with only aggregator option and clauses definition" =>
      Operators.AggregatorOptionAndClausesDefintion,
    "a nested rule with only aggregator option no definitions" =>
      Operators.AggregatorOptionAndNoDefintion,
    "a nested rule with only clauses option and aggregator definition" =>
      Operators.ClausesOptionAndAggregatorDefintion,
    "a nested rule with no options and aggregator and clauses definitions" =>
      Operators.NoOptionAndBothDefintions
  }

  for {desc, module} <- operators do
    describe desc do
      it_behaves_like ValidOperatorRule,
        rule_module: unquote(module),
        aggregator: &Enum.all?/1
    end
  end
end
