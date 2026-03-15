defmodule LangkaOrderManagement.Employee do
  import Ecto.Query, warn: false

  alias LangkaOrderManagement.{ContextUtil, Employee.Employee, Repo}

  def list_employees_with_paging(filters) do
    query =
      Employee
      |> ContextUtil.list(filters)

    employees = Repo.all(query)

    count =
      query
      |> exclude(:order_by)
      |> exclude(:select)
      |> select([employee], count(employee.id))
      |> Repo.one()

    {employees, count}
  end

  def get_employee(id), do: Repo.get(Employee, id)

  def create_employee(attrs) do
    %Employee{}
    |> Employee.changeset(attrs)
    |> Repo.insert()
  end

  def update_employee(%Employee{} = employee, attrs) do
    employee
    |> Employee.changeset(attrs)
    |> Repo.update()
  end

  def delete_employee(%Employee{} = employee) do
    employee
    |> Employee.changeset(%{removed_datetime: DateTime.truncate(DateTime.utc_now(), :second)})
    |> Repo.update()
  end
end
