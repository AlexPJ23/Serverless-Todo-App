const input  = document.querySelector("#taskInput") as HTMLInputElement;
const addButton = document.querySelector("#addTask") as HTMLButtonElement;
const taskList = document.querySelector("#taskList") as HTMLUListElement;

const apiUrl = "http://localhost:3000/tasks";
const fetchTasks = async () => {
    const response = await fetch(apiUrl);
    if (!response.ok) {
        throw new Error("Failed to fetch tasks");
    }
    return response.json();
    }
    
const addTask = async (task: string) => {
    const response = await fetch(apiUrl, {
        method: "POST",
        headers: {
            "Content-Type": "application/json",
        },
        body: JSON.stringify({ task }),
    });
    if (!response.ok) {
        throw new Error("Failed to add task");
    }
    return response.json();
}
const deleteTask = async (id: string) => {
    const response = await fetch(`${apiUrl}/${id}`, {
        method: "DELETE",
    });
    if (!response.ok) {
        throw new Error("Failed to delete task");
    }
    return response.json();
}
const renderTasks = async () => {
    try {
        const tasks = await fetchTasks();
        taskList.innerHTML = "";
        tasks.forEach((task: { id: string; task: string }) => {
            const li = document.createElement("li");
            li.textContent = task.task;
            const deleteButton = document.createElement("button");
            deleteButton.textContent = "Delete";
            deleteButton.onclick = async () => {
                await deleteTask(task.id);
                renderTasks();
            };
            li.appendChild(deleteButton);
            taskList.appendChild(li);
        });
    } catch (error) {
        console.error(error);
    }
}
