import { Blockchain, SandboxContract, TreasuryContract } from '@ton-community/sandbox';
import { toNano } from 'ton-core';
import { Task5, AdminWithdrawalProfit } from '../wrappers/Task5';

describe('Task5', () => {
    let blockchain: Blockchain;
    let task5: SandboxContract<Task5>;

    beforeEach(async () => {
        blockchain = await Blockchain.create();
        const wallets: SandboxContract<TreasuryContract>[] = await blockchain.createWallets(1);
        const deployer = await blockchain.treasury('deployer');
        task5 = blockchain.openContract(await Task5.fromInit(BigInt(432), deployer.address));
        const deployResult = await task5.send(
            deployer.getSender(),
            {
                value: toNano('100'),
            },
            {
                $$type: 'Deploy',
                queryId: 0n,
            }
        );

        await task5.send(deployer.getSender(), { value: BigInt(100000000) }, {
            $$type: 'AdminWithdrawalProfit',
            queryId: BigInt(0),
        } as AdminWithdrawalProfit);

        console.log(await task5.getProfit());
        // expect(deployResult.transactions).toHaveTransaction({
        //     from: deployer.address,
        //     to: task5.address,
        //     deploy: true,
        //     success: true,
        // });
    });

    it('test', async () => {});
});
