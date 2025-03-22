#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/fs.h>
#include <linux/uaccess.h>
#include <linux/sched.h>
#include <linux/slab.h>
#include <linux/mm.h>
#include <linux/syscalls.h>
#include <linux/pid.h>
#include <linux/kprobes.h>
#include <linux/sched/task.h>

#define DEVICE_NAME "user_func_exec"
#define BUFFER_SIZE 1024

static struct kprobe kp;
static int major_number;
// static char buffer[BUFFER_SIZE];
static pid_t target_pid;
static unsigned long target_func_addr;




// Pre-handler for the fork system call
static int handler_pre(struct kprobe *p, struct pt_regs *regs)
{


    struct task_struct *task;
    struct pt_regs *regs_t;
    if(target_pid!=0 && target_func_addr!=0 && current->pid == target_pid){
        

        // Find the task_struct for the given PID
        task = pid_task(find_vpid(target_pid), PIDTYPE_PID);
        if (!task) {
            printk("Unable to get the task.");
            return 0;
        }

        // Get the register set for the task
        regs_t = task_pt_regs(task);

        // Modify the instruction pointer to point to the target function
        regs_t->ip = target_func_addr;

        // Notify the user that the function has been executed
        printk("Function at 0x%lx executed in process %d\n", target_func_addr, target_pid);
        
    }

    return 0;
}



static int device_open(struct inode *inode, struct file *file) {
    printk(KERN_INFO "Device opened\n");
    return 0;
}

static int device_release(struct inode *inode, struct file *file) {
    printk(KERN_INFO "Device closed\n");
    return 0;
}

static ssize_t device_write(struct file *file, const char __user *user_buffer, size_t count, loff_t *offset) {
    char temp_buffer[BUFFER_SIZE];
    if (copy_from_user(temp_buffer, user_buffer, count)) {
        return -EFAULT;
    }
    temp_buffer[count] = '\0';

    // Parse PID and function address from the user buffer
    if (sscanf(temp_buffer, "%d %lx", &target_pid, &target_func_addr) != 2) {
        return -EINVAL;
    }

    printk(KERN_INFO "Received PID: %d, Function Address: 0x%lx\n", target_pid, target_func_addr);
    return count;
}

static ssize_t device_read(struct file *file, char __user *user_buffer, size_t count, loff_t *offset) {
    
    target_pid=0;
    target_func_addr=0;
    printk("Reseted the forker module by seting target_func_addr=0 and target_pid=0. \n");

    return count;
}

static struct file_operations fops = {
    .open = device_open,
    .release = device_release,
    .read = device_read,
    .write = device_write,
};

static int __init my_module_init(void) {
    major_number = register_chrdev(0, DEVICE_NAME, &fops);
    if (major_number < 0) {
        printk(KERN_ALERT "Failed to register a major number\n");
        return major_number;
    }
    kp.pre_handler = handler_pre;
    // Set the symbol name to the fork system call
    kp.symbol_name = "kernel_clone";

    // Register the kprobe
    if (register_kprobe(&kp) < 0) {
        pr_err("Failed to register kprobe\n");
        return -1;
    }

    pr_info("Kprobe registered successfully\n");

    printk(KERN_INFO "Registered device with major number %d\n", major_number);
    return 0;
}

static void __exit my_module_exit(void) {
    unregister_chrdev(major_number, DEVICE_NAME);
    // Unregister the kprobe
    unregister_kprobe(&kp);
    pr_info("Kprobe unregistered\n");
    printk(KERN_INFO "Unregistered device\n");
}

module_init(my_module_init);
module_exit(my_module_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Your Name");
MODULE_DESCRIPTION("Kernel module to execute user-space functions");
