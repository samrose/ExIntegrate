defmodule ExIntegrate.RunTest do
  use ExUnit.Case, async: true

  alias ExIntegrate.Core.Run
  alias ExIntegrate.Core.Pipeline
  alias ExIntegrate.Core.Step

  @pipeline_params %{
    "name" => "say hello",
    "steps" => [
      %{
        "name" => "say hello",
        "command" => "echo",
        "args" => ["hello, "]
      }
    ]
  }

  @dependent_pipeline_params %{
    "depends_on" => "say hello",
    "name" => "say world",
    "steps" => [
      %{
        "name" => "say world",
        "command" => "echo",
        "args" => ["world!"]
      }
    ]
  }

  @run_params %{
    "pipelines" => [@pipeline_params]
  }

  @dependent_run_params %{
    "pipelines" => [@pipeline_params, @dependent_pipeline_params]
  }

  test "create a run with a dependent pipeline" do
    run = Run.new(@dependent_run_params)
    [pipeline1 | [pipeline2 | []]] = Run.pipelines(run)
    assert [^pipeline2] = Graph.neighbors(run.pipeline_graph, pipeline1)
  end

  test "update pipeline" do
    run = Run.new(@run_params)
    assert pipeline = hd(run.pipelines)
    updated_pipeline = %Pipeline{name: "updated pipeline", steps: []}

    assert run = Run.put_pipeline(run, pipeline, updated_pipeline)

    assert Run.has_pipeline?(run, updated_pipeline),
           """
           Expected pipeline graph:

           #{inspect(run.pipeline_graph)}

           to have pipeline:

           #{inspect(pipeline)}.
           """
  end

  test "checks if a run has failed" do
    run = Run.new(@run_params)
    refute Run.failed?(run)

    pipeline = run |> Run.pipelines() |> hd()

    failed_pipeline = %Pipeline{
      name: "a failed pipeline",
      steps: [%Step{status_code: 1, name: "a failed step", command: "foo", args: []}]
    }

    failed_run = Run.put_pipeline(run, pipeline, failed_pipeline)
    assert Run.failed?(failed_run), "Expected run to have failed.\n\n#{inspect(failed_run)}"
  end

  test "look up a pipeline by name" do
    run = Run.new(%{"pipelines" => [@pipeline_params]})
    pipeline_name = @pipeline_params["name"]
    assert %Pipeline{} = run[pipeline_name]
  end

  test "get and update a run's pipeline" do
    run = Run.new(%{"pipelines" => [@pipeline_params]})
    pipeline_name = @pipeline_params["name"]
    new_pipeline = %Pipeline{name: "new pipeline", steps: []}

    assert {%{name: ^pipeline_name}, updated_run} =
             Run.get_and_update(run, pipeline_name, fn pipeline ->
               {pipeline, new_pipeline}
             end)

    assert ^new_pipeline = updated_run[new_pipeline.name]
  end

  test "modify and read a run's active pipelines" do
    run = Run.new(@run_params)
    pipeline = run |> Run.pipelines() |> hd()

    run = Run.activate_pipelines(run, [pipeline])
    assert [pipeline] == Run.active_pipelines(run)
  end
end
