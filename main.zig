const std = @import("std");

pub fn SmallList(T: type, size: usize) type {
    const alloc_size = @sizeOf(T) * size;
    return struct {
        stack: std.heap.StackFallbackAllocator(alloc_size),
        list: std.ArrayListUnmanaged(T),
        alloc: ?std.mem.Allocator = null,

        const Self = @This();

        pub fn init(gpa: std.mem.Allocator) Self {
            const stack = std.heap.stackFallback(alloc_size, gpa);
            return Self{ .stack = stack, .list = .empty };
        }

        // called internally
        inline fn inner_init(self: *Self) !void {
            if (self.alloc) |_| return;

            self.alloc = self.stack.get();
            try self.list.ensureTotalCapacityPrecise(self.alloc.?, size);
        }

        pub fn append(self: *Self, item: T) !void {
            try self.inner_init();
            return self.list.append(self.alloc.?, item);
        }

        pub fn deinit(self: *Self) void {
            self.inner_init() catch return; // errors on allocation failure.
            self.list.deinit(self.alloc.?);
        }
    };
}

pub fn main() !void {
    var gpa_alloc: std.heap.DebugAllocator(.{}) = .init;
    const gpa = gpa_alloc.allocator();

    var list: SmallList(u16, 8) = .init(gpa);
    defer list.deinit();

    for (0..10) |i| {
        try list.append(@intCast(i));
        std.debug.print("{?}: {}\n", .{
            i,
            list.stack.fixed_buffer_allocator.ownsPtr(@ptrCast(list.list.items.ptr)),
        });
    }
    // 0: true
    // 1: true
    // 2: true
    // 3: true
    // 4: true
    // 5: true
    // 6: true
    // 7: false
    // 8: false
    // 9: false

}
