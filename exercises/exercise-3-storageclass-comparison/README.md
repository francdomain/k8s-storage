# Exercise 3: StorageClass Comparison

This exercise demonstrates the difference between Retain and Delete reclaim policies.

## Steps:

1. **Create StorageClasses**: One with Retain policy, one with Delete policy
2. **Create PVCs**: One using each StorageClass
3. **Observe Behavior**: Delete PVCs and see what happens to PVs
4. **Manual Cleanup**: Clean up retained PVs manually