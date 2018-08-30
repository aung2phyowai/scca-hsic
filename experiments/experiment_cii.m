%% Experiment C. II: Increasing the Number of Noise Variables
%
% This script demonstrates SCCA-HSIC when the number of related variables
% increases.

clear

% SCCA-HSIC
hyperparams.M = 1; % number of components
hyperparams.normtypeX = 1; % norm constraint on u
hyperparams.normtypeY = 1; % norm constraint on v
hyperparams.Rep = 15; % number of random initializations
hyperparams.eps = 1e-7; % convergence limit
hyperparams.sigma1 = []; % std of rbf kernel by median trick
hyperparams.sigma2 = []; % std of rbf kernel by median trick
hyperparams.maxit = 500; % maximum number of iterations
hyperparams.flag = 1;

% data dimensions
p = 10:10:40;
q = 10:10:40;
n = 300;

% setting
indeps = 3;
func = 1:5;
repss = 10;

% preallocate
result(length(func),1).hsic_train = [];
result(length(func),1).u = [];
result(length(func),1).v = [];
result(length(func),1).hsic_test = [];
result(length(func),1).f1 = [];


for ff = 1:length(func)
    for ll = 1:length(p)
        
        % ground truth
        correct_v = zeros(q(ll),1); correct_v([1,2]) = 1;
        correct_u = zeros(p(ll),1); correct_u(1:3) = 1;
        
        % generate data
        rng('shuffle')
        [X,Y] = generate_data(n,p(ll),q(ll),3,func(ff));
        
        % tune hyperparameters for a random sample from this dataset
        rsamp = randsample(size(X,1), round(0.4 * size(X,1)));
        c1 = 0.5:0.5:2.5; c2 = 0.5:0.5:2.5;
        [c1_1,c2_1] = tune_hypers(X(rsamp,:),Y(rsamp,:),'scca-hsic',3,c1,c2);
      

        for rep = 1:repss
            % standardise and partition
            Xn = zscore(X); Yn = zscore(Y);
            [~,indices] = partition(size(X,1), 3);
            train = indices ~= 1; test = indices == 1;
            Xtrain = Xn(train,:); Xtest = Xn(test,:);
            Ytrain = Yn(train,:); Ytest = Yn(test,:);
            
            % compute ground truth
            Xground(:,ll,rep) = X(test,1) + X(test,2) + X(test,3);
            Yground(:,ll,rep) = Y(test,1) + Y(test,2);            
            Kxground = rbf_kernel(Xground(:,ll,rep));
            Kyground = centre_kernel(rbf_kernel(Yground(:,ll,rep)));
            hsic_ground(ff,ll,rep) = f(Kxground,Kyground);
            
            % learn the model parameters u and v
            hyperparams.Cx = c1_1; hyperparams.Cy = c2_1;
            [u,v,hsic_train] = scca_hsic(Xtrain,Ytrain,hyperparams);
            
            % compute the test hsic
            Kxtest = rbf_kernel(Xtest * u);
            Kytest = centre_kernel(rbf_kernel(Ytest * v));
            
            result(ff,1).hsic_train(ll,rep) = hsic_train;
            result(ff,1).u{ll,rep} = u;
            result(ff,1).v{ll,rep} = v;
            result(ff,1).hsic_test(ll,rep) = f(Kxtest,Kytest);
            
            f1_u = f1_score(u,correct_u); f1_v = f1_score(v,correct_v);
            result(ff,1).f1(ll,rep) = mean([f1_u f1_v]);
        end
    end
end

% averages over the repetitions
for i = 1:length(func)
    F1_mean(i,:) = mean(result(i,1).f1,2);
    HSIC_mean(i,:) = mean(result(i,1).hsic_test,2);
end

%%  visualise 
marks = 's:';
figure
subplot(121)
hold on
h1 = plot(mean(mean(hsic_ground,3)),'k--');
h2 = errorbar(mean(HSIC_mean),std(HSIC_mean),marks,'MarkerSize',20,'MarkerEdgeColor','auto','MarkerFaceColor','none','linewidth',2);
set(gca,'xtick',1:4,'xticklabel',[10,20,30,40],'fontweight','bold','fontsize',16)
xlabel('Noise Variables')
ylabel('Test HSIC')
box on
axis square
ylim([0 0.085])

set(findobj(gca,'type','line'),'linew',2)
set(gca,'linew',2)

subplot(122)
hold on
errorbar(mean(F1_mean),std(F1_mean),marks,'MarkerSize',15,'MarkerEdgeColor','auto','MarkerFaceColor','none',...
    'linewidth',2)
ylim([0 1])
set(gca,'xtick',1:4,'xticklabel',[10,20,30,40],'fontweight','bold','fontsize',14)
xlabel('Noise Variables')
ylabel('F1')
box on
set(findobj(gca,'type','line'),'linew',2)
set(gca,'linew',2)
axis square









