const std = @import("std");
const microzig = @import("microzig");
const md5 = @import("../../Md5.zig");

const rp2040 = microzig.hal;
const time = rp2040.time;
const gpio = rp2040.gpio;
const usb = rp2040.usb;

var ep1_out_cfg: usb.EndpointConfiguration = .{
    .descriptor = &usb.EndpointDescriptor{
        .descriptor_type = usb.DescType.Endpoint,
        .endpoint_address = usb.Dir.Out.endpoint(1),
        .attributes = @intFromEnum(usb.TransferType.Bulk),
        .max_packet_size = 64,
        .interval = 0,
    },
    .endpoint_control_index = 2,
    .buffer_control_index = 3,
    .data_buffer_index = 2,
    .next_pid_1 = false,
};

var ep1_in_cfg: usb.EndpointConfiguration = .{
    .descriptor = &usb.EndpointDescriptor{
        .descriptor_type = usb.DescType.Endpoint,
        .endpoint_address = usb.Dir.In.endpoint(1),
        .attributes = @intFromEnum(usb.TransferType.Bulk),
        .max_packet_size = 64,
        .interval = 0,
    },
    .endpoint_control_index = 1,
    .buffer_control_index = 2,
    .data_buffer_index = 3,
    .next_pid_1 = false,
};

pub fn createDeviceConfig(
    out_callback: *const fn (dc: *usb.DeviceConfiguration, data: []const u8) void,
    in_callback: *const fn (dc: *usb.DeviceConfiguration, data: []const u8) void,
) usb.DeviceConfiguration {
    ep1_out_cfg.callback = out_callback;
    ep1_in_cfg.callback = in_callback;

    // construct the device configuration
    return usb.DeviceConfiguration{
        .device_descriptor = &.{
            .descriptor_type = usb.DescType.Device,
            .bcd_usb = 0x0110,
            .device_class = 0,
            .device_subclass = 0,
            .device_protocol = 0,
            .max_packet_size0 = 64,
            .vendor = 0,
            .product = 1,
            .bcd_device = 0,
            .manufacturer_s = 1,
            .product_s = 2,
            .serial_s = 0,
            .num_configurations = 1,
        },
        .interface_descriptor = &.{
            .descriptor_type = usb.DescType.Interface,
            .interface_number = 0,
            .alternate_setting = 0,
            // We have two endpoints (EP0 IN/OUT don't count)
            .num_endpoints = 2,
            .interface_class = 0xff,
            .interface_subclass = 0,
            .interface_protocol = 0,
            .interface_s = 0,
        },
        .config_descriptor = &.{
            .descriptor_type = usb.DescType.Config,
            // This is calculated via the sizes of underlying descriptors contained in this configuration.
            // ConfigurationDescriptor(9) + InterfaceDescriptor(9) * 1 + EndpointDescriptor(8) * 2
            .total_length = 34,
            .num_interfaces = 1,
            .configuration_value = 1,
            .configuration_s = 0,
            .attributes = 0xc0,
            .max_power = 0x32,
        },
        .lang_descriptor = "\x04\x03\x09\x04", // length || string descriptor (0x03) || Engl (0x0409)
        .descriptor_strings = &.{
            // ugly unicode :|
            "R\x00a\x00s\x00p\x00b\x00e\x00r\x00r\x00y\x00 \x00P\x00i\x00",
            "P\x00i\x00c\x00o\x00 \x00T\x00e\x00s\x00t\x00 \x00D\x00e\x00v\x00i\x00c\x00e\x00",
        },
        // Here we pass all endpoints to the config
        // Dont forget to pass EP0_[IN|OUT] in the order seen below!
        .endpoints = .{
            &usb.EP0_OUT_CFG,
            &usb.EP0_IN_CFG,
            &ep1_out_cfg,
            &ep1_in_cfg,
        },
    };
}

const led = gpio.num(25);
const uart = rp2040.uart.num(0);
const baud_rate = 115200;
const uart_tx_pin = gpio.num(0);
const uart_rx_pin = gpio.num(1);

const MessageError = error{
    MessageTooLong,
};

// there is no useful allocator available using microzig.
const Message = struct {
    response: [64]u8 = undefined,
    hash_buffer: [4]u32 = undefined,
    buffer: [4096]u8 = undefined,
    num_bytes_received: u32,
    num_bytes_remaining: u32,
};
var message = Message{
    .num_bytes_received = 0,
    .num_bytes_remaining = 0,
};

fn ep1_in_callback(dc: *usb.DeviceConfiguration, _: []const u8) void {
    // prepare to receive the next 64 byte message.
    usb.Usb.callbacks.usb_start_rx(
        dc.endpoints[2], // EP1_OUT_CFG,
        64,
    );
}

fn ep1_out_callback(dc: *usb.DeviceConfiguration, data: []const u8) void {
    handle_ep1_out_callback(dc, data) catch |err| {
        // send error as result message
        const fmt_msg = std.fmt.bufPrint(&message.response, "error: {s}", .{@errorName(err)}) catch unreachable;
        usb.Usb.callbacks.usb_start_tx(
            dc.endpoints[3], // EP1_IN_CFG,
            fmt_msg,
        );
    };
}

fn handle_ep1_out_callback(dc: *usb.DeviceConfiguration, data: []const u8) !void {
    if (message.num_bytes_remaining == 0) {
        // receiving new request -> first message format is .{ msg_len: u32, msg_part: [60]u8 }
        const msg_len: u32 = @as(*const u32, @ptrCast(@alignCast(data[0..4]))).*;
        if (msg_len > message.buffer.len) {
            const fmt_msg = try std.fmt.bufPrint(&message.response, "msg too long. got len {d}.", .{msg_len});
            usb.Usb.callbacks.usb_start_tx(
                dc.endpoints[3], // EP1_IN_CFG,
                fmt_msg,
            );
            return;
        }

        message.num_bytes_remaining = @max(0, @as(i33, msg_len) - 60);
        message.num_bytes_received = @min(60, msg_len);
        std.mem.copyForwards(u8, &message.buffer, data[4..(4 + message.num_bytes_received)]);
    } else {
        // receiving request continuation
        const input_len = @min(64, message.num_bytes_remaining);
        message.num_bytes_remaining -= input_len;
        std.mem.copyForwards(u8, message.buffer[message.num_bytes_received..], data[0..input_len]);
        message.num_bytes_received += input_len;
    }

    if (message.num_bytes_remaining == 0) {
        // request data complete, compute hash and prepare to send
        var hash: [4]u32 = message.hash_buffer;
        md5.computeMd5(message.buffer[0..message.num_bytes_received], &hash);
        const response: *[32]u8 = message.response[0..32];

        try md5.toHexString(&hash, response);
        usb.Usb.callbacks.usb_start_tx(
            dc.endpoints[3], // EP1_IN_CFG,
            response,
        );
    } else {
        // switch back to receiving data by sending a 0 byte response.
        usb.Usb.callbacks.usb_start_tx(
            dc.endpoints[3], // EP1_IN_CFG,
            &.{},
        );
    }
}

var device_configuration: usb.DeviceConfiguration = undefined;

pub fn main() !void {
    device_configuration = createDeviceConfig(ep1_out_callback, ep1_in_callback);

    led.set_function(.sio);
    led.set_direction(.out);
    led.put(1);

    uart.apply(.{
        .baud_rate = baud_rate,
        .tx_pin = uart_tx_pin,
        .rx_pin = uart_rx_pin,
        .clock_config = rp2040.clock_config,
    });

    rp2040.uart.init_logger(uart);

    // First we initialize the USB clock
    rp2040.usb.Usb.init_clk();
    // Then initialize the USB device using the configuration defined above
    rp2040.usb.Usb.init_device(&device_configuration) catch unreachable;
    var old: u64 = time.get_time_since_boot().to_us();
    var new: u64 = 0;
    while (true) {
        // You can now poll for USB events
        rp2040.usb.Usb.task(
            false, // debug output over UART [Y/n]
        ) catch unreachable;

        new = time.get_time_since_boot().to_us();
        if (new - old > 500000) {
            old = new;
            led.toggle();
        }
    }
}
